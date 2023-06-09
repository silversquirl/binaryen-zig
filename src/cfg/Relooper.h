/*
 * Copyright 2016 WebAssembly Community Group participants
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
This is an optimized C++ implemention of the Relooper algorithm originally
developed as part of Emscripten. This implementation includes optimizations
added since the original academic paper [1] was published about it.

[1] Alon Zakai. 2011. Emscripten: an LLVM-to-JavaScript compiler. In Proceedings
of the ACM international conference companion on Object oriented programming
systems languages and applications companion (SPLASH '11). ACM, New York, NY,
USA, 301-312. DOI=10.1145/2048147.2048224
http://doi.acm.org/10.1145/2048147.2048224
*/

#include <assert.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include <deque>
#include <list>
#include <map>
#include <memory>
#include <set>

#include "support/insert_ordered.h"
#include "wasm-builder.h"
#include "wasm.h"

namespace CFG {

class RelooperBuilder : public wasm::Builder {
  wasm::Index labelHelper;

public:
  RelooperBuilder(wasm::Module& wasm, wasm::Index labelHelper)
    : wasm::Builder(wasm), labelHelper(labelHelper) {}

  wasm::LocalGet* makeGetLabel() {
    return makeLocalGet(labelHelper, wasm::Type::i32);
  }
  wasm::LocalSet* makeSetLabel(wasm::Index value) {
    return makeLocalSet(labelHelper, makeConst(wasm::Literal(int32_t(value))));
  }
  wasm::Binary* makeCheckLabel(wasm::Index value) {
    return makeBinary(
      wasm::EqInt32, makeGetLabel(), makeConst(wasm::Literal(int32_t(value))));
  }

  // breaks are on blocks, as they can be specific, we make one wasm block per
  // basic block
  wasm::Break* makeBlockBreak(int id) {
    return wasm::Builder::makeBreak(getBlockBreakName(id));
  }
  // continues are on shapes, as there is one per loop, and if we have more than
  // one going there, it is irreducible control flow anyhow
  wasm::Break* makeShapeContinue(int id) {
    return wasm::Builder::makeBreak(getShapeContinueName(id));
  }

  wasm::Name getBlockBreakName(int id) {
    return wasm::Name(std::string("block$") + std::to_string(id) + "$break");
  }
  wasm::Name getShapeContinueName(int id) {
    return wasm::Name(std::string("shape$") + std::to_string(id) + "$continue");
  }
};

struct Relooper;
struct Block;
struct Shape;

// Info about a branching from one block to another
struct Branch {
  enum FlowType {
    Direct = 0, // We will directly reach the right location through other
                // means, no need for continue or break
    Break = 1,
    Continue = 2
  };
  // If not NULL, this shape is the relevant one for purposes of getting to the
  // target block. We break or continue on it
  Shape* Ancestor = nullptr;
  // If Ancestor is not NULL, this says whether to break or continue
  Branch::FlowType Type;

  // A branch either has a condition expression if the block ends in ifs, or if
  // the block ends in a switch, then a list of indexes, which becomes the
  // indexes in the table of the switch. If not a switch, the condition can be
  // any expression (or nullptr for the branch taken when no other condition is
  // true) A condition must not have side effects, as the Relooper can reorder
  // or eliminate condition checking. This must not have side effects.
  wasm::Expression* Condition;
  // Switches are rare, so have just a pointer for their values. This contains
  // the values for which the branch will be taken, or for the default it is
  // simply not present.
  std::unique_ptr<std::vector<wasm::Index>> SwitchValues;

  // If provided, code that is run right before the branch is taken. This is
  // useful for phis.
  wasm::Expression* Code;

  Branch(wasm::Expression* ConditionInit, wasm::Expression* CodeInit = nullptr);

  Branch(std::vector<wasm::Index>&& ValuesInit,
         wasm::Expression* CodeInit = nullptr);

  // Emits code for branch
  wasm::Expression*
  Render(RelooperBuilder& Builder, Block* Target, bool SetLabel);
};

using BlockSet = wasm::InsertOrderedSet<Block*>;
using BlockBranchMap = wasm::InsertOrderedMap<Block*, Branch*>;

// Represents a basic block of code - some instructions that end with a
// control flow modifier (a branch, return or throw).
struct Block {
  // Reference to the relooper containing this block.
  Relooper* relooper;
  // Branches become processed after we finish the shape relevant to them. For
  // example, when we recreate a loop, branches to the loop start become
  // continues and are now processed. When we calculate what shape to generate
  // from a set of blocks, we ignore processed branches. Blocks own the Branch
  // objects they use, and destroy them when done.
  BlockBranchMap BranchesOut;
  BlockSet BranchesIn;
  BlockBranchMap ProcessedBranchesOut;
  BlockSet ProcessedBranchesIn;
  Shape* Parent = nullptr; // The shape we are directly inside
  int Id = -1; // A unique identifier, defined when added to relooper
  // The code in this block. This can be arbitrary wasm code, including internal
  // control flow, it should just not branch to the outside
  wasm::Expression* Code;
  // If nullptr, then this block ends in ifs (or nothing). otherwise, this block
  // ends in a switch, done on this condition
  wasm::Expression* SwitchCondition;
  // If true, we are a multiple entry, so reaching us requires setting the label
  // variable
  bool IsCheckedMultipleEntry;

  Block(Relooper* relooper,
        wasm::Expression* CodeInit,
        wasm::Expression* SwitchConditionInit = nullptr);

  // Add a branch: if the condition holds we branch (or if null, we branch if
  // all others failed) Note that there can be only one branch from A to B (if
  // you need multiple conditions for the branch, create a more interesting
  // expression in the Condition). If a Block has no outgoing branches, the
  // contents in Code must contain a terminating instruction, as the relooper
  // doesn't know whether you want control flow to stop with an `unreachable` or
  // a `return` or something else (if you forget to do this, control flow may
  // continue into the block that happens to be emitted right after it).
  // Internally, adding a branch only adds the outgoing branch. The matching
  // incoming branch on the target is added by the Relooper itself as it works.
  void AddBranchTo(Block* Target,
                   wasm::Expression* Condition,
                   wasm::Expression* Code = nullptr);

  // Add a switch branch: if the switch condition is one of these values, we
  // branch (or if the list is empty, we are the default) Note that there can be
  // only one branch from A to B (if you need multiple values for the branch,
  // that's what the array and default are for).
  void AddSwitchBranchTo(Block* Target,
                         std::vector<wasm::Index>&& Values,
                         wasm::Expression* Code = nullptr);

  // Emit code for the block, including its contents and branchings out
  wasm::Expression* Render(RelooperBuilder& Builder, bool InLoop);
};

// Represents a structured control flow shape, one of
//
//  Simple: No control flow at all, just instructions in a single
//          basic block.
//
//  Multiple: A shape with at least one entry. We may visit one of
//            the entries, or none, before continuing to the next
//            shape after this.
//
//  Loop: An infinite loop. We assume the property that a loop
//        will always visit one of its entries, and so for example
//        we cannot have a loop containing a multiple and nothing
//        else (since we might not visit any of the multiple's
//        blocks). Multiple entries are possible for the block,
//        however, which is necessary for irreducible control
//        flow, of course.
//

struct SimpleShape;
struct MultipleShape;
struct LoopShape;

struct Shape {
  // A unique identifier. Used to identify loops, labels are Lx where x is the
  // Id. Defined when added to relooper
  int Id = -1;
  // The shape that will appear in the code right after this one
  Shape* Next = nullptr;
  // The shape that control flow gets to naturally (if there is Next, then this
  // is Next)
  Shape* Natural;

  enum ShapeType { Simple, Multiple, Loop };
  ShapeType Type;

  Shape(ShapeType TypeInit) : Type(TypeInit) {}
  virtual ~Shape() = default;

  virtual wasm::Expression* Render(RelooperBuilder& Builder, bool InLoop) = 0;

  static SimpleShape* IsSimple(Shape* It) {
    return It && It->Type == Simple ? (SimpleShape*)It : NULL;
  }
  static MultipleShape* IsMultiple(Shape* It) {
    return It && It->Type == Multiple ? (MultipleShape*)It : NULL;
  }
  static LoopShape* IsLoop(Shape* It) {
    return It && It->Type == Loop ? (LoopShape*)It : NULL;
  }
};

struct SimpleShape : public Shape {
  Block* Inner = nullptr;

  SimpleShape() : Shape(Simple) {}
  wasm::Expression* Render(RelooperBuilder& Builder, bool InLoop) override;
};

using IdShapeMap = std::map<int, Shape*>;

struct MultipleShape : public Shape {
  IdShapeMap InnerMap; // entry block ID -> shape

  MultipleShape() : Shape(Multiple) {}

  wasm::Expression* Render(RelooperBuilder& Builder, bool InLoop) override;
};

struct LoopShape : public Shape {
  Shape* Inner = nullptr;

  BlockSet Entries; // we must visit at least one of these

  LoopShape() : Shape(Loop) {}
  wasm::Expression* Render(RelooperBuilder& Builder, bool InLoop) override;
};

// Implements the relooper algorithm for a function's blocks.
//
// Usage:
//  1. Instantiate this struct.
//  2. Create the blocks you have. Each should have its
//     branchings in specified (the branchings out will
//     be calculated by the relooper).
//  3. Call Render().
//
// Implementation details: The Relooper instance takes ownership of the blocks,
// branches and shapes when created using the `AddBlock` etc. methods, and frees
// them when done.
struct Relooper {
  wasm::Module* Module;
  std::deque<std::unique_ptr<Block>> Blocks;
  std::deque<std::unique_ptr<Branch>> Branches;
  std::deque<std::unique_ptr<Shape>> Shapes;
  Shape* Root;
  bool MinSize;
  int BlockIdCounter;
  int ShapeIdCounter;

  Relooper(wasm::Module* ModuleInit);

  // Creates a new block associated with (and cleaned up along) this relooper.
  Block* AddBlock(wasm::Expression* CodeInit,
                  wasm::Expression* SwitchConditionInit = nullptr);
  // Creates a new branch associated with (and cleaned up along) this relooper.
  Branch* AddBranch(wasm::Expression* ConditionInit,
                    wasm::Expression* CodeInit);
  // Creates a new branch associated with (and cleaned up along) this relooper.
  Branch* AddBranch(std::vector<wasm::Index>&& ValuesInit,
                    wasm::Expression* CodeInit = nullptr);
  // Creates a new simple shape associated with (and cleaned up along) this
  // relooper.
  SimpleShape* AddSimpleShape();
  // Creates a new multiple shape associated with (and cleaned up along) this
  // relooper.
  MultipleShape* AddMultipleShape();
  // Creates a new loop shape associated with (and cleaned up along) this
  // relooper.
  LoopShape* AddLoopShape();

  // Calculates the shapes
  void Calculate(Block* Entry);

  // Renders the result.
  wasm::Expression* Render(RelooperBuilder& Builder);

  // Sets us to try to minimize size
  void SetMinSize(bool MinSize_) { MinSize = MinSize_; }
};

using BlockBlockSetMap = wasm::InsertOrderedMap<Block*, BlockSet>;

#ifdef RELOOPER_DEBUG
struct Debugging {
  static void Dump(Block* Curr, const char* prefix = NULL);
  static void Dump(BlockSet& Blocks, const char* prefix = NULL);
  static void Dump(Shape* S, const char* prefix = NULL);
};
#endif

} // namespace CFG
