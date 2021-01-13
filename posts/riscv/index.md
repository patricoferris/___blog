---
title: A Short Introduction to RISC-V 
description: A long-form post about high-level RISC-V concepts along with technical tibits to keep you curious.
date: 2021-01-13
authors: 
  - Patrick Ferris
topics:
  - hardware
  - risc-v
reading: 
  - name: "The RISC-V Reader: An Open Architecture Atlas"
    description: A very thorough and well-explained ISA manual by David Patterson and Andrew Waterman from which a lot of the technical details of this post were derived. 
    url: http://www.riscvbook.com/ 
---

"Keep it simple unless for good reason" that's how Turing Award winning and vice chair of the board of directors of the RISC-V Foundation, [David Patterson](https://en.wikipedia.org/wiki/David_Patterson_%28computer_scientist%29), explained the underlying principles of the reduced instruction set computer (RISC) in [1985](https://www.youtube.com/watch?v=5NjGLyBx0wg). This short essay explores the fundamental characteristics of RISC-V, how it differs from more conventional instruction set architectures (ISA) and peppered throughout are interesting technical tibits about the design of RISC-V. 

## Abstraction

A timeless quote from the great [David Wheeler](https://en.wikipedia.org/wiki/David_Wheeler_(computer_scientist)) is often used again and again within the field of computer science.

> All problems in computer science can be solved by another level of indirection : [citation](https://www2.dmst.aueb.gr/dds/pubs/inbook/beautiful_code/html/Spi07g.html)

The extent to which this idea permeates all areas of problem-solving particularly in computer science is hard to express. The fundamental principle is abstraction. Whether that be in the [various layers of the OSI network model](https://en.wikipedia.org/wiki/OSI_model), [declarative languages for performing database queries](https://www.infoworld.com/article/3219795/what-is-sql-the-lingua-franca-of-data-analysis.html) or in this case telling a computer what to do.

An ISA is bridge between hardware and software. It provides a framework and philosophy for designing hardware and compiling languages. ISAs are divided into two fairly over-simplified but useful camps: reduced (RISC) and complex (CISC) instruction set computers. [x86](https://en.wikipedia.org/wiki/X86) would be the classic CISC architecture known for its [enormous number of instructions](https://fgiesen.wordpress.com/2016/08/25/how-many-x86-instructions-are-there/#:~:text=To%20not%20leave%20you%20hanging,too%2C%20by%20the%20way) and [licensing](https://jolt.law.harvard.edu/digest/intel-and-the-x86-architecture-a-legal-perspective). 
RISC-V in contrast, is a free and open-source ISA specification. You are free to take it and do what you will with it.

## A Broad Overview

Before diving into interesting characteristics and design decisions, it's useful to 

## Simplicity

A RISC architecture does not imply simplicity. It is quite possible to bake-in complex behaviour into a seemingly reduced or simple specification. RISC-V opts to follow the principle "keep it simple unless for good reason". This manifests itself in a number of ways. 

### Fixed-width and specifier location-sharing formats

The instruction encoding format uses just six types and all are 32-bits wide, this can vastly reduce the complexity of the decoding logic in a CPU. Moreover, the register locations (i.e. the bit ranges where the register values are kept within the instruction) are the same across the formats. For performance, this allows registers to be accessed before decoding even begins which can help reduce the critical time path. 

<div class="diagram-container">
  <img class="diagram" style="width: 100%" alt="An example of location-sharing between formats" src="./diagrams/instr.svg" />
  <p><em>Figure: A diagram indicating the location-sharing between R-type and I-type instruction formats.</em></p>
</div>

This is also seen in the immediate fields, the most significant bit of any of them is always bit 32 of the instruction making sign-extension logic simpler and potentially faster. All RISC-V immediates are sign-extended using the most significant bit and this can
provide simpler instruction patterns. 

Consider a small example: 

```
int drop_byte (int n) {
  return n & 0xFFFFFF00;
}
```

Which when compiled with [RISC-V 64-bit compiler with `-O3`](https://godbolt.org/z/res4dG) gives:

```
andi    a0,a0,-256
ret
```

No extra faff needs to happen with the immediate (`0xFFFFFF00`) because it is automatically sign-extended to `0xFFFFFFFFFFFFFF00`. On MIPS architectures this is not the case as logical operations are zero-extended (p.45 of [MIPS IV Instruction Set](https://www.cs.cmu.edu/afs/cs/academic/class/15740-f97/public/doc/mips-isa.pdf)).

The B-type instruction exemplifies the careful decision-making that has taken place for the different formats: 

<div style="text-align: center;">
  <img class="diagram" style="width: 100%" alt="The B-type instruction format" src="./diagrams/btype.svg" />
  <p><em>Figure: Location-sharing, MSB-bit in place 31 and dropped lower bit of the B-type instruction.</em></p>
</div>

Here we can see: 

 - The most-significant bit of the immediate is located at the 32nd bit of the instruction. 
 - The registers are in the same place as the other instructions.
 - The lower bit (`imm[0]`) is left out, this is because the relative branching offset is performed in multiples of 2 bytes. The RISC-V architecture is word-aligned — on a 32-bit architecture this amounts to instructions being stored at multiples of 4 bytes but because of 16-bit compressed format they can be on 2 byte boundaries.


### A good reason for complexity

Although not part of the general-purpose extension ( G ), the compressed instruction format ( C ) specification is often implemented. With this extension we lose the property of fixed-width instructions introducing complexity at the front-end of CPUs during instruction fetch and decode. [Ariane's increased complexity](https://cva6.readthedocs.io/en/latest/id_stage.html) illustrates this perfectly indicating the four scenarios: two compressed instructions in the 4 bytes of a regular instruction, a regular instruction misaligned by two sandwiching compress instructions, a series of unaligned regular instructions or just a regular instruction. So what's the good reason for this? Andrew Waterman has the answer in his master's thesis ["Improving Energy Efficiency and Reducing Code Size with RISC-V Compressed"](https://people.eecs.berkeley.edu/~krste/papers/waterman-ms.pdf). The major improvements are: 

 1. Fewer instruction bits are fetched in general by encoding common instructions in only half the size of a regular instruction. 
 2. Code size is greatly reduced when using the compressed extension. 
 3. Cache misses are more rare because the instruction working set is reduced (less pressure on the instruction cache).

Whilst all good reasons for RVC existing, the modularity of the ISA allows for very small implementations (say in a microcontroller or FPGA) to forgo the additional logic. This is another key principle of RISC-V.

## Modularity

The RISC-V ISA is designed to be modular. Instructions are broken into distinct extensions which are named (and often referred to by the first letter of that name). If you are familiar with subtyping in programming languages then the concept is quite analogous. 

### Combinations

RISC-V extensions can be combined in order to give more powerful ISAs. Take, for example, RV32G (RV32IMAFD) which combines many of the necessary extensions for writing general-purpose CPUs that can afford complex ALUs and floating-point units (FPUs). Another example is the ability to work backwards like the yet unratified, RV32E base integer extension. Here, only after finding a desire for an even smaller base ISA than RV32I did the RISC-V specification writers decide to include draft for RV32E with only 16 integer registers for smaller applications. This could still be combined with others.

### Optional features

The base integer extension (I) is the cornerstone of all the other ones. This tends to be the bare minimum you need to implement in order to have a useful CPU encompassing instructions like `add`, `xor`, `lw` (load word) and `beq` (branch equal). But note even here the simplicity in design is apparent, there are no multiplication instructions -- this would require additional circuitry for the arithmetic logic unit (ALU) which should be optional rather than mandatory in RISC-V implementations. Not all problems require blazing fast performance; cost (small IoT devices), complexity (teaching) and size (fitting on a small FPGA) are all equally valid requirements that RISC-V can accommodate thanks to its modularity.

The [Ibex core](https://ibex-core.readthedocs.io/en/latest/01_overview/compliance.html) is a perfect example of how modularity with compile-time configurations can enable a very flexible core to fit many "...embedded control applications". Multiplication can be enabled, compressed instructions can be enabled and even the (at the time of writing) unratified bit manipulation extension can be enabled depending on the intended use of the core. As if by magic, we have stumbled upon yet another key principle of RISC-V, extensibility.

## Extensibility

Purposefully leaving plenty of opcode space combined with being open-source and modular enables RISC-V's extensibility. This is by far the most interesting and powerful area of active research (and fun-filled tinkering) that RISC-V has to offer. 

Modern ISAs (such as *x86*) try to do everything. This can make them extremely powerful, but also bloated due to backwards compatibility guarantees, not to mention confusing for many at the start. The classic example of this is *x86* [AAA](https://www.felixcloutier.com/x86/aaa) instruction for [binary-coded decimal](https://en.wikipedia.org/wiki/Intel_BCD_opcode) which is rarely used anymore but the method of deprecation is more confusing than that of the modular, extensible RISC-V. 

### Examples

There are quite a few examples of extending the RISC-V ISA in order to benefit hardware-accelerators. In "[A near-threshold RISC-V core
with DSP extensions for scalable IoT Endpoint Devices](https://arxiv.org/pdf/1608.08376v1.pdf)" as part of the parallel ultra-low power (PULP) platform, they introduced DSP instructions. One example instruction they add is `p.add` which perform register addition with round and normalization by a specific number of bits (see Table I of the paper).

## Education 

RISC-V's simplicity, open-source ideology and modularity all combine in such a way to make it extremely useful in an academic setting. Not only for research (new CPU designs, custom extensions, tools etc.) but for undergraduates (like myself) where the smaller size and ability to look at many examples of RISC-V compatible hardware designed in Verilog makes it more accessible. 

## Conclusion