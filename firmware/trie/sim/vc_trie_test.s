
vc_trie_test.o:     file format pe-x86-64


Disassembly of section .text:

0000000000000000 <_Z5htonlj>:
   0:	89 c8                	mov    %ecx,%eax
   2:	0f c8                	bswap  %eax
   4:	c3                   	ret
   5:	90                   	nop
   6:	90                   	nop
   7:	90                   	nop
   8:	90                   	nop
   9:	90                   	nop
   a:	90                   	nop
   b:	90                   	nop
   c:	90                   	nop
   d:	90                   	nop
   e:	90                   	nop
   f:	90                   	nop

Disassembly of section .text$_Z6printfPKcz:

0000000000000000 <_Z6printfPKcz>:
   0:	56                   	push   %rsi
   1:	53                   	push   %rbx
   2:	48 83 ec 38          	sub    $0x38,%rsp
   6:	48 8d 74 24 58       	lea    0x58(%rsp),%rsi
   b:	48 89 54 24 58       	mov    %rdx,0x58(%rsp)
  10:	48 89 cb             	mov    %rcx,%rbx
  13:	b9 01 00 00 00       	mov    $0x1,%ecx
  18:	4c 89 44 24 60       	mov    %r8,0x60(%rsp)
  1d:	4c 89 4c 24 68       	mov    %r9,0x68(%rsp)
  22:	48 89 74 24 28       	mov    %rsi,0x28(%rsp)
  27:	ff 15 00 00 00 00    	call   *0x0(%rip)        # 2d <_Z6printfPKcz+0x2d>
  2d:	49 89 f0             	mov    %rsi,%r8
  30:	48 89 da             	mov    %rbx,%rdx
  33:	48 89 c1             	mov    %rax,%rcx
  36:	e8 00 00 00 00       	call   3b <_Z6printfPKcz+0x3b>
  3b:	48 83 c4 38          	add    $0x38,%rsp
  3f:	5b                   	pop    %rbx
  40:	5e                   	pop    %rsi
  41:	c3                   	ret
  42:	90                   	nop
  43:	90                   	nop
  44:	90                   	nop
  45:	90                   	nop
  46:	90                   	nop
  47:	90                   	nop
  48:	90                   	nop
  49:	90                   	nop
  4a:	90                   	nop
  4b:	90                   	nop
  4c:	90                   	nop
  4d:	90                   	nop
  4e:	90                   	nop
  4f:	90                   	nop

Disassembly of section .text$_Z7sprintfPcPKcz:

0000000000000000 <_Z7sprintfPcPKcz>:
   0:	48 83 ec 38          	sub    $0x38,%rsp
   4:	4c 89 44 24 50       	mov    %r8,0x50(%rsp)
   9:	4c 8d 44 24 50       	lea    0x50(%rsp),%r8
   e:	4c 89 4c 24 58       	mov    %r9,0x58(%rsp)
  13:	4c 89 44 24 28       	mov    %r8,0x28(%rsp)
  18:	e8 00 00 00 00       	call   1d <_Z7sprintfPcPKcz+0x1d>
  1d:	48 83 c4 38          	add    $0x38,%rsp
  21:	c3                   	ret
  22:	90                   	nop
  23:	90                   	nop
  24:	90                   	nop
  25:	90                   	nop
  26:	90                   	nop
  27:	90                   	nop
  28:	90                   	nop
  29:	90                   	nop
  2a:	90                   	nop
  2b:	90                   	nop
  2c:	90                   	nop
  2d:	90                   	nop
  2e:	90                   	nop
  2f:	90                   	nop

Disassembly of section .text$_ZN6VCTrie6insertERK3IP6jj:

0000000000000000 <_ZN6VCTrie6insertERK3IP6jj>:
   0:	41 57                	push   %r15
   2:	41 56                	push   %r14
   4:	41 55                	push   %r13
   6:	41 54                	push   %r12
   8:	55                   	push   %rbp
   9:	57                   	push   %rdi
   a:	56                   	push   %rsi
   b:	53                   	push   %rbx
   c:	48 83 ec 38          	sub    $0x38,%rsp
  10:	8b 5a 0c             	mov    0xc(%rdx),%ebx
  13:	44 89 84 24 90 00 00 	mov    %r8d,0x90(%rsp)
  1a:	00 
  1b:	48 89 ce             	mov    %rcx,%rsi
  1e:	45 89 cf             	mov    %r9d,%r15d
  21:	8b 0a                	mov    (%rdx),%ecx
  23:	83 bc 24 90 00 00 00 	cmpl   $0x1c,0x90(%rsp)
  2a:	1c 
  2b:	44 8b 42 04          	mov    0x4(%rdx),%r8d
  2f:	48 89 f0             	mov    %rsi,%rax
  32:	44 8b 4a 08          	mov    0x8(%rdx),%r9d
  36:	0f 86 2b 03 00 00    	jbe    367 <_ZN6VCTrie6insertERK3IP6jj+0x367>
  3c:	8b bc 24 90 00 00 00 	mov    0x90(%rsp),%edi
  43:	48 89 94 24 88 00 00 	mov    %rdx,0x88(%rsp)
  4a:	00 
  4b:	45 31 d2             	xor    %r10d,%r10d
  4e:	4c 8d 35 80 00 00 00 	lea    0x80(%rip),%r14        # d5 <_ZN6VCTrie6insertERK3IP6jj+0xd5>
  55:	44 89 bc 24 98 00 00 	mov    %r15d,0x98(%rsp)
  5c:	00 
  5d:	4c 8d 25 40 00 00 00 	lea    0x40(%rip),%r12        # a4 <_ZN6VCTrie6insertERK3IP6jj+0xa4>
  64:	44 8d 6f e4          	lea    -0x1c(%rdi),%r13d
  68:	e9 7d 00 00 00       	jmp    ea <_ZN6VCTrie6insertERK3IP6jj+0xea>
  6d:	0f 1f 00             	nopl   (%rax)
  70:	85 d2                	test   %edx,%edx
  72:	0f 85 c1 00 00 00    	jne    139 <_ZN6VCTrie6insertERK3IP6jj+0x139>
  78:	8b 7e 14             	mov    0x14(%rsi),%edi
  7b:	4d 8d 7b 04          	lea    0x4(%r11),%r15
  7f:	8d 57 01             	lea    0x1(%rdi),%edx
  82:	89 56 14             	mov    %edx,0x14(%rsi)
  85:	42 8b 6c be 08       	mov    0x8(%rsi,%r15,4),%ebp
  8a:	8d 55 01             	lea    0x1(%rbp),%edx
  8d:	42 89 54 be 08       	mov    %edx,0x8(%rsi,%r15,4)
  92:	4c 8d 3d 00 01 00 00 	lea    0x100(%rip),%r15        # 199 <_ZN6VCTrie6insertERK3IP6jj+0x199>
  99:	43 3b 14 9f          	cmp    (%r15,%r11,4),%edx
  9d:	0f 83 a5 00 00 00    	jae    148 <_ZN6VCTrie6insertERK3IP6jj+0x148>
  a3:	89 50 04             	mov    %edx,0x4(%rax)
  a6:	4b 8b 2c de          	mov    (%r14,%r11,8),%rbp
  aa:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
  b0:	89 d0                	mov    %edx,%eax
  b2:	44 89 c2             	mov    %r8d,%edx
  b5:	d1 e9                	shr    %ecx
  b7:	41 83 c2 01          	add    $0x1,%r10d
  bb:	c1 e2 1f             	shl    $0x1f,%edx
  be:	43 0f af 04 9c       	imul   (%r12,%r11,4),%eax
  c3:	41 d1 e8             	shr    %r8d
  c6:	09 d1                	or     %edx,%ecx
  c8:	44 89 ca             	mov    %r9d,%edx
  cb:	41 d1 e9             	shr    %r9d
  ce:	c1 e2 1f             	shl    $0x1f,%edx
  d1:	41 09 d0             	or     %edx,%r8d
  d4:	89 da                	mov    %ebx,%edx
  d6:	48 01 e8             	add    %rbp,%rax
  d9:	d1 eb                	shr    %ebx
  db:	c1 e2 1f             	shl    $0x1f,%edx
  de:	41 09 d1             	or     %edx,%r9d
  e1:	45 39 ea             	cmp    %r13d,%r10d
  e4:	0f 84 be 00 00 00    	je     1a8 <_ZN6VCTrie6insertERK3IP6jj+0x1a8>
  ea:	45 89 d3             	mov    %r10d,%r11d
  ed:	8b 38                	mov    (%rax),%edi
  ef:	8b 50 04             	mov    0x4(%rax),%edx
  f2:	41 c1 eb 03          	shr    $0x3,%r11d
  f6:	f6 c1 01             	test   $0x1,%cl
  f9:	0f 85 71 ff ff ff    	jne    70 <_ZN6VCTrie6insertERK3IP6jj+0x70>
  ff:	85 ff                	test   %edi,%edi
 101:	74 0d                	je     110 <_ZN6VCTrie6insertERK3IP6jj+0x110>
 103:	4b 8b 2c de          	mov    (%r14,%r11,8),%rbp
 107:	89 fa                	mov    %edi,%edx
 109:	eb a5                	jmp    b0 <_ZN6VCTrie6insertERK3IP6jj+0xb0>
 10b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
 110:	8b 7e 14             	mov    0x14(%rsi),%edi
 113:	4d 8d 7b 04          	lea    0x4(%r11),%r15
 117:	8d 57 01             	lea    0x1(%rdi),%edx
 11a:	89 56 14             	mov    %edx,0x14(%rsi)
 11d:	42 8b 6c be 08       	mov    0x8(%rsi,%r15,4),%ebp
 122:	8d 55 01             	lea    0x1(%rbp),%edx
 125:	42 89 54 be 08       	mov    %edx,0x8(%rsi,%r15,4)
 12a:	4c 8d 3d 00 01 00 00 	lea    0x100(%rip),%r15        # 231 <_ZN6VCTrie6insertERK3IP6jj+0x231>
 131:	43 3b 14 9f          	cmp    (%r15,%r11,4),%edx
 135:	73 11                	jae    148 <_ZN6VCTrie6insertERK3IP6jj+0x148>
 137:	89 10                	mov    %edx,(%rax)
 139:	4b 8b 2c de          	mov    (%r14,%r11,8),%rbp
 13d:	e9 6e ff ff ff       	jmp    b0 <_ZN6VCTrie6insertERK3IP6jj+0xb0>
 142:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 148:	89 7e 14             	mov    %edi,0x14(%rsi)
 14b:	48 8b 94 24 88 00 00 	mov    0x88(%rsp),%rdx
 152:	00 
 153:	42 89 6c 9e 18       	mov    %ebp,0x18(%rsi,%r11,4)
 158:	44 8b 02             	mov    (%rdx),%r8d
 15b:	44 8b 4a 04          	mov    0x4(%rdx),%r9d
 15f:	48 8d 4e 5c          	lea    0x5c(%rsi),%rcx
 163:	8b 42 08             	mov    0x8(%rdx),%eax
 166:	8b 52 0c             	mov    0xc(%rdx),%edx
 169:	41 0f c9             	bswap  %r9d
 16c:	41 0f c8             	bswap  %r8d
 16f:	0f c8                	bswap  %eax
 171:	0f ca                	bswap  %edx
 173:	89 44 24 20          	mov    %eax,0x20(%rsp)
 177:	89 54 24 28          	mov    %edx,0x28(%rsp)
 17b:	48 8d 15 00 00 00 00 	lea    0x0(%rip),%rdx        # 182 <_ZN6VCTrie6insertERK3IP6jj+0x182>
 182:	e8 00 00 00 00       	call   187 <_ZN6VCTrie6insertERK3IP6jj+0x187>
 187:	83 46 58 01          	addl   $0x1,0x58(%rsi)
 18b:	b8 01 00 00 00       	mov    $0x1,%eax
 190:	48 83 c4 38          	add    $0x38,%rsp
 194:	5b                   	pop    %rbx
 195:	5e                   	pop    %rsi
 196:	5f                   	pop    %rdi
 197:	5d                   	pop    %rbp
 198:	41 5c                	pop    %r12
 19a:	41 5d                	pop    %r13
 19c:	41 5e                	pop    %r14
 19e:	41 5f                	pop    %r15
 1a0:	c3                   	ret
 1a1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
 1a8:	48 8b 94 24 88 00 00 	mov    0x88(%rsp),%rdx
 1af:	00 
 1b0:	44 8b bc 24 98 00 00 	mov    0x98(%rsp),%r15d
 1b7:	00 
 1b8:	44 89 bc 24 98 00 00 	mov    %r15d,0x98(%rsp)
 1bf:	00 
 1c0:	4c 8d 25 00 00 00 00 	lea    0x0(%rip),%r12        # 1c7 <_ZN6VCTrie6insertERK3IP6jj+0x1c7>
 1c7:	4c 8d 2d 40 00 00 00 	lea    0x40(%rip),%r13        # 20e <_ZN6VCTrie6insertERK3IP6jj+0x20e>
 1ce:	48 89 94 24 88 00 00 	mov    %rdx,0x88(%rsp)
 1d5:	00 
 1d6:	8b 94 24 90 00 00 00 	mov    0x90(%rsp),%edx
 1dd:	0f 1f 00             	nopl   (%rax)
 1e0:	45 8d 5a ff          	lea    -0x1(%r10),%r11d
 1e4:	31 ff                	xor    %edi,%edi
 1e6:	41 c1 eb 03          	shr    $0x3,%r11d
 1ea:	45 85 d2             	test   %r10d,%r10d
 1ed:	4c 0f 44 df          	cmove  %rdi,%r11
 1f1:	47 8b 34 9c          	mov    (%r12,%r11,4),%r14d
 1f5:	45 85 f6             	test   %r14d,%r14d
 1f8:	74 2e                	je     228 <_ZN6VCTrie6insertERK3IP6jj+0x228>
 1fa:	48 8d 68 08          	lea    0x8(%rax),%rbp
 1fe:	49 89 eb             	mov    %rbp,%r11
 201:	41 83 3b 1e          	cmpl   $0x1e,(%r11)
 205:	0f 87 c5 00 00 00    	ja     2d0 <_ZN6VCTrie6insertERK3IP6jj+0x2d0>
 20b:	41 83 7b 08 1e       	cmpl   $0x1e,0x8(%r11)
 210:	0f 87 ba 00 00 00    	ja     2d0 <_ZN6VCTrie6insertERK3IP6jj+0x2d0>
 216:	83 c7 01             	add    $0x1,%edi
 219:	49 83 c3 0c          	add    $0xc,%r11
 21d:	41 39 fe             	cmp    %edi,%r14d
 220:	75 df                	jne    201 <_ZN6VCTrie6insertERK3IP6jj+0x201>
 222:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 228:	45 89 d3             	mov    %r10d,%r11d
 22b:	41 c1 eb 03          	shr    $0x3,%r11d
 22f:	f6 c1 01             	test   $0x1,%cl
 232:	0f 84 e8 00 00 00    	je     320 <_ZN6VCTrie6insertERK3IP6jj+0x320>
 238:	44 8b 70 04          	mov    0x4(%rax),%r14d
 23c:	45 85 f6             	test   %r14d,%r14d
 23f:	0f 85 12 01 00 00    	jne    357 <_ZN6VCTrie6insertERK3IP6jj+0x357>
 245:	8b 7e 14             	mov    0x14(%rsi),%edi
 248:	4d 8d 7b 04          	lea    0x4(%r11),%r15
 24c:	8d 6f 01             	lea    0x1(%rdi),%ebp
 24f:	89 6e 14             	mov    %ebp,0x14(%rsi)
 252:	42 8b 6c be 08       	mov    0x8(%rsi,%r15,4),%ebp
 257:	44 8d 75 01          	lea    0x1(%rbp),%r14d
 25b:	46 89 74 be 08       	mov    %r14d,0x8(%rsi,%r15,4)
 260:	4c 8d 3d 00 01 00 00 	lea    0x100(%rip),%r15        # 367 <_ZN6VCTrie6insertERK3IP6jj+0x367>
 267:	47 3b 34 9f          	cmp    (%r15,%r11,4),%r14d
 26b:	0f 83 d7 fe ff ff    	jae    148 <_ZN6VCTrie6insertERK3IP6jj+0x148>
 271:	44 89 70 04          	mov    %r14d,0x4(%rax)
 275:	48 8d 05 80 00 00 00 	lea    0x80(%rip),%rax        # 2fc <_ZN6VCTrie6insertERK3IP6jj+0x2fc>
 27c:	4a 8b 3c d8          	mov    (%rax,%r11,8),%rdi
 280:	44 89 f0             	mov    %r14d,%eax
 283:	43 0f af 44 9d 00    	imul   0x0(%r13,%r11,4),%eax
 289:	45 89 c3             	mov    %r8d,%r11d
 28c:	d1 e9                	shr    %ecx
 28e:	41 c1 e3 1f          	shl    $0x1f,%r11d
 292:	41 d1 e8             	shr    %r8d
 295:	41 83 c2 01          	add    $0x1,%r10d
 299:	44 09 d9             	or     %r11d,%ecx
 29c:	45 89 cb             	mov    %r9d,%r11d
 29f:	41 d1 e9             	shr    %r9d
 2a2:	41 c1 e3 1f          	shl    $0x1f,%r11d
 2a6:	48 01 f8             	add    %rdi,%rax
 2a9:	45 09 d8             	or     %r11d,%r8d
 2ac:	41 89 db             	mov    %ebx,%r11d
 2af:	d1 eb                	shr    %ebx
 2b1:	41 c1 e3 1f          	shl    $0x1f,%r11d
 2b5:	45 09 d9             	or     %r11d,%r9d
 2b8:	44 39 d2             	cmp    %r10d,%edx
 2bb:	0f 83 1f ff ff ff    	jae    1e0 <_ZN6VCTrie6insertERK3IP6jj+0x1e0>
 2c1:	48 8b 94 24 88 00 00 	mov    0x88(%rsp),%rdx
 2c8:	00 
 2c9:	e9 8a fe ff ff       	jmp    158 <_ZN6VCTrie6insertERK3IP6jj+0x158>
 2ce:	66 90                	xchg   %ax,%ax
 2d0:	41 39 fe             	cmp    %edi,%r14d
 2d3:	0f 84 4f ff ff ff    	je     228 <_ZN6VCTrie6insertERK3IP6jj+0x228>
 2d9:	48 8b 94 24 88 00 00 	mov    0x88(%rsp),%rdx
 2e0:	00 
 2e1:	44 8b bc 24 98 00 00 	mov    0x98(%rsp),%r15d
 2e8:	00 
 2e9:	44 39 94 24 90 00 00 	cmp    %r10d,0x90(%rsp)
 2f0:	00 
 2f1:	0f 82 61 fe ff ff    	jb     158 <_ZN6VCTrie6insertERK3IP6jj+0x158>
 2f7:	48 8d 04 7f          	lea    (%rdi,%rdi,2),%rax
 2fb:	48 8d 54 85 00       	lea    0x0(%rbp,%rax,4),%rdx
 300:	8b 84 24 90 00 00 00 	mov    0x90(%rsp),%eax
 307:	89 4a 04             	mov    %ecx,0x4(%rdx)
 30a:	44 29 d0             	sub    %r10d,%eax
 30d:	44 89 7a 08          	mov    %r15d,0x8(%rdx)
 311:	89 02                	mov    %eax,(%rdx)
 313:	31 c0                	xor    %eax,%eax
 315:	e9 76 fe ff ff       	jmp    190 <_ZN6VCTrie6insertERK3IP6jj+0x190>
 31a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 320:	44 8b 30             	mov    (%rax),%r14d
 323:	45 85 f6             	test   %r14d,%r14d
 326:	75 2f                	jne    357 <_ZN6VCTrie6insertERK3IP6jj+0x357>
 328:	8b 7e 14             	mov    0x14(%rsi),%edi
 32b:	4d 8d 7b 04          	lea    0x4(%r11),%r15
 32f:	8d 6f 01             	lea    0x1(%rdi),%ebp
 332:	89 6e 14             	mov    %ebp,0x14(%rsi)
 335:	42 8b 6c be 08       	mov    0x8(%rsi,%r15,4),%ebp
 33a:	44 8d 75 01          	lea    0x1(%rbp),%r14d
 33e:	46 89 74 be 08       	mov    %r14d,0x8(%rsi,%r15,4)
 343:	4c 8d 3d 00 01 00 00 	lea    0x100(%rip),%r15        # 44a <_GLOBAL__sub_I__Z5htonlj+0x5a>
 34a:	47 3b 34 9f          	cmp    (%r15,%r11,4),%r14d
 34e:	0f 83 f4 fd ff ff    	jae    148 <_ZN6VCTrie6insertERK3IP6jj+0x148>
 354:	44 89 30             	mov    %r14d,(%rax)
 357:	48 8d 05 80 00 00 00 	lea    0x80(%rip),%rax        # 3de <BRAM_DEPTHS+0x2de>
 35e:	4a 8b 3c d8          	mov    (%rax,%r11,8),%rdi
 362:	e9 19 ff ff ff       	jmp    280 <_ZN6VCTrie6insertERK3IP6jj+0x280>
 367:	45 31 d2             	xor    %r10d,%r10d
 36a:	e9 49 fe ff ff       	jmp    1b8 <_ZN6VCTrie6insertERK3IP6jj+0x1b8>
 36f:	90                   	nop

Disassembly of section .text.startup:

0000000000000000 <main>:
   0:	41 57                	push   %r15
   2:	41 56                	push   %r14
   4:	41 55                	push   %r13
   6:	41 54                	push   %r12
   8:	55                   	push   %rbp
   9:	57                   	push   %rdi
   a:	56                   	push   %rsi
   b:	53                   	push   %rbx
   c:	48 81 ec 48 03 00 00 	sub    $0x348,%rsp
  13:	e8 00 00 00 00       	call   18 <main+0x18>
  18:	48 8d 9c 24 60 01 00 	lea    0x160(%rsp),%rbx
  1f:	00 
  20:	41 b8 08 00 00 00    	mov    $0x8,%r8d
  26:	48 8d 15 11 00 00 00 	lea    0x11(%rip),%rdx        # 3e <main+0x3e>
  2d:	48 89 d9             	mov    %rbx,%rcx
  30:	e8 00 00 00 00       	call   35 <main+0x35>
  35:	31 c9                	xor    %ecx,%ecx
  37:	ff 15 00 00 00 00    	call   *0x0(%rip)        # 3d <main+0x3d>
  3d:	89 c1                	mov    %eax,%ecx
  3f:	e8 00 00 00 00       	call   44 <main+0x44>
  44:	48 8d 0d 26 00 00 00 	lea    0x26(%rip),%rcx        # 71 <main+0x71>
  4b:	e8 00 00 00 00       	call   50 <main+0x50>
  50:	48 8b 05 b8 00 00 00 	mov    0xb8(%rip),%rax        # 10f <main+0x10f>
  57:	66 0f 6f 05 b0 00 00 	movdqa 0xb0(%rip),%xmm0        # 10f <main+0x10f>
  5e:	00 
  5f:	31 ed                	xor    %ebp,%ebp
  61:	c7 84 24 18 01 00 00 	movl   $0x0,0x118(%rsp)
  68:	00 00 00 00 
  6c:	48 8d 35 40 00 00 00 	lea    0x40(%rip),%rsi        # b3 <main+0xb3>
  73:	48 89 84 24 d0 00 00 	mov    %rax,0xd0(%rsp)
  7a:	00 
  7b:	48 8d 44 24 60       	lea    0x60(%rsp),%rax
  80:	48 89 44 24 38       	mov    %rax,0x38(%rsp)
  85:	0f 29 84 24 c0 00 00 	movaps %xmm0,0xc0(%rsp)
  8c:	00 
  8d:	66 0f ef c0          	pxor   %xmm0,%xmm0
  91:	0f 11 84 24 d8 00 00 	movups %xmm0,0xd8(%rsp)
  98:	00 
  99:	0f 11 84 24 e8 00 00 	movups %xmm0,0xe8(%rsp)
  a0:	00 
  a1:	0f 11 84 24 f8 00 00 	movups %xmm0,0xf8(%rsp)
  a8:	00 
  a9:	0f 11 84 24 08 01 00 	movups %xmm0,0x108(%rsp)
  b0:	00 
  b1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
  b8:	48 8b 7c 24 38       	mov    0x38(%rsp),%rdi
  bd:	66 0f ef c0          	pxor   %xmm0,%xmm0
  c1:	48 89 d9             	mov    %rbx,%rcx
  c4:	0f 29 44 24 60       	movaps %xmm0,0x60(%rsp)
  c9:	48 89 fa             	mov    %rdi,%rdx
  cc:	0f 29 44 24 70       	movaps %xmm0,0x70(%rsp)
  d1:	e8 00 00 00 00       	call   d6 <main+0xd6>
  d6:	48 8d 54 24 64       	lea    0x64(%rsp),%rdx
  db:	48 89 d9             	mov    %rbx,%rcx
  de:	e8 00 00 00 00       	call   e3 <main+0xe3>
  e3:	48 8d 54 24 68       	lea    0x68(%rsp),%rdx
  e8:	48 89 d9             	mov    %rbx,%rcx
  eb:	e8 00 00 00 00       	call   f0 <main+0xf0>
  f0:	48 8d 54 24 6c       	lea    0x6c(%rsp),%rdx
  f5:	48 89 d9             	mov    %rbx,%rcx
  f8:	e8 00 00 00 00       	call   fd <main+0xfd>
  fd:	48 8d 54 24 5c       	lea    0x5c(%rsp),%rdx
 102:	48 89 d9             	mov    %rbx,%rcx
 105:	e8 00 00 00 00       	call   10a <main+0x10a>
 10a:	48 8d 54 24 70       	lea    0x70(%rsp),%rdx
 10f:	48 89 d9             	mov    %rbx,%rcx
 112:	e8 00 00 00 00       	call   117 <main+0x117>
 117:	48 8d 54 24 74       	lea    0x74(%rsp),%rdx
 11c:	48 89 d9             	mov    %rbx,%rcx
 11f:	e8 00 00 00 00       	call   124 <main+0x124>
 124:	48 8d 54 24 78       	lea    0x78(%rsp),%rdx
 129:	48 89 d9             	mov    %rbx,%rcx
 12c:	e8 00 00 00 00       	call   131 <main+0x131>
 131:	48 8d 54 24 7c       	lea    0x7c(%rsp),%rdx
 136:	48 89 d9             	mov    %rbx,%rcx
 139:	e8 00 00 00 00       	call   13e <main+0x13e>
 13e:	48 8d 54 24 58       	lea    0x58(%rsp),%rdx
 143:	48 89 d9             	mov    %rbx,%rcx
 146:	e8 00 00 00 00       	call   14b <main+0x14b>
 14b:	8b 44 24 68          	mov    0x68(%rsp),%eax
 14f:	8b 54 24 6c          	mov    0x6c(%rsp),%edx
 153:	48 8d 8c 24 80 00 00 	lea    0x80(%rsp),%rcx
 15a:	00 
 15b:	4c 8d a4 24 c0 00 00 	lea    0xc0(%rsp),%r12
 162:	00 
 163:	44 8b 4c 24 64       	mov    0x64(%rsp),%r9d
 168:	44 8b 44 24 60       	mov    0x60(%rsp),%r8d
 16d:	0f c8                	bswap  %eax
 16f:	0f ca                	bswap  %edx
 171:	89 44 24 20          	mov    %eax,0x20(%rsp)
 175:	89 54 24 28          	mov    %edx,0x28(%rsp)
 179:	48 8d 15 00 00 00 00 	lea    0x0(%rip),%rdx        # 180 <main+0x180>
 180:	41 0f c9             	bswap  %r9d
 183:	41 0f c8             	bswap  %r8d
 186:	e8 00 00 00 00       	call   18b <main+0x18b>
 18b:	44 8b 4c 24 58       	mov    0x58(%rsp),%r9d
 190:	48 89 fa             	mov    %rdi,%rdx
 193:	4c 89 e1             	mov    %r12,%rcx
 196:	44 8b 44 24 5c       	mov    0x5c(%rsp),%r8d
 19b:	e8 00 00 00 00       	call   1a0 <main+0x1a0>
 1a0:	41 89 c1             	mov    %eax,%r9d
 1a3:	85 c0                	test   %eax,%eax
 1a5:	0f 85 bf 00 00 00    	jne    26a <main+0x26a>
 1ab:	44 8b 6c 24 5c       	mov    0x5c(%rsp),%r13d
 1b0:	8b 54 24 60          	mov    0x60(%rsp),%edx
 1b4:	44 8b 54 24 64       	mov    0x64(%rsp),%r10d
 1b9:	44 8b 5c 24 68       	mov    0x68(%rsp),%r11d
 1be:	8b 7c 24 6c          	mov    0x6c(%rsp),%edi
 1c2:	41 83 fd 1c          	cmp    $0x1c,%r13d
 1c6:	0f 86 46 01 00 00    	jbe    312 <main+0x312>
 1cc:	45 8d 75 e4          	lea    -0x1c(%r13),%r14d
 1d0:	4c 89 e0             	mov    %r12,%rax
 1d3:	4c 8d 05 80 00 00 00 	lea    0x80(%rip),%r8        # 25a <main+0x25a>
 1da:	eb 45                	jmp    221 <main+0x221>
 1dc:	0f 1f 40 00          	nopl   0x0(%rax)
 1e0:	44 89 c8             	mov    %r9d,%eax
 1e3:	d1 ea                	shr    %edx
 1e5:	41 83 c1 01          	add    $0x1,%r9d
 1e9:	c1 e8 03             	shr    $0x3,%eax
 1ec:	0f af 0c 86          	imul   (%rsi,%rax,4),%ecx
 1f0:	49 03 0c c0          	add    (%r8,%rax,8),%rcx
 1f4:	48 89 c8             	mov    %rcx,%rax
 1f7:	44 89 d1             	mov    %r10d,%ecx
 1fa:	41 d1 ea             	shr    %r10d
 1fd:	c1 e1 1f             	shl    $0x1f,%ecx
 200:	09 ca                	or     %ecx,%edx
 202:	44 89 d9             	mov    %r11d,%ecx
 205:	41 d1 eb             	shr    %r11d
 208:	c1 e1 1f             	shl    $0x1f,%ecx
 20b:	41 09 ca             	or     %ecx,%r10d
 20e:	89 f9                	mov    %edi,%ecx
 210:	d1 ef                	shr    %edi
 212:	c1 e1 1f             	shl    $0x1f,%ecx
 215:	41 09 cb             	or     %ecx,%r11d
 218:	45 39 ce             	cmp    %r9d,%r14d
 21b:	0f 84 f7 00 00 00    	je     318 <main+0x318>
 221:	8b 48 04             	mov    0x4(%rax),%ecx
 224:	f6 c2 01             	test   $0x1,%dl
 227:	0f 44 08             	cmove  (%rax),%ecx
 22a:	85 c9                	test   %ecx,%ecx
 22c:	75 b2                	jne    1e0 <main+0x1e0>
 22e:	48 89 ea             	mov    %rbp,%rdx
 231:	48 8d 0d 36 00 00 00 	lea    0x36(%rip),%rcx        # 26e <main+0x26e>
 238:	e8 00 00 00 00       	call   23d <main+0x23d>
 23d:	be 01 00 00 00       	mov    $0x1,%esi
 242:	48 89 d9             	mov    %rbx,%rcx
 245:	e8 00 00 00 00       	call   24a <main+0x24a>
 24a:	89 f0                	mov    %esi,%eax
 24c:	48 81 c4 48 03 00 00 	add    $0x348,%rsp
 253:	5b                   	pop    %rbx
 254:	5e                   	pop    %rsi
 255:	5f                   	pop    %rdi
 256:	5d                   	pop    %rbp
 257:	41 5c                	pop    %r12
 259:	41 5d                	pop    %r13
 25b:	41 5e                	pop    %r14
 25d:	41 5f                	pop    %r15
 25f:	c3                   	ret
 260:	48 8b 6c 24 40       	mov    0x40(%rsp),%rbp
 265:	4c 8b 64 24 48       	mov    0x48(%rsp),%r12
 26a:	48 83 c5 01          	add    $0x1,%rbp
 26e:	48 81 fd c0 68 03 00 	cmp    $0x368c0,%rbp
 275:	0f 85 3d fe ff ff    	jne    b8 <main+0xb8>
 27b:	48 8d 0d 4b 00 00 00 	lea    0x4b(%rip),%rcx        # 2cd <main+0x2cd>
 282:	e8 00 00 00 00       	call   287 <main+0x287>
 287:	8b 94 24 d4 00 00 00 	mov    0xd4(%rsp),%edx
 28e:	48 8d 0d 51 00 00 00 	lea    0x51(%rip),%rcx        # 2e6 <main+0x2e6>
 295:	e8 00 00 00 00       	call   29a <main+0x29a>
 29a:	8b 94 24 18 01 00 00 	mov    0x118(%rsp),%edx
 2a1:	48 8d 0d 61 00 00 00 	lea    0x61(%rip),%rcx        # 309 <main+0x309>
 2a8:	e8 00 00 00 00       	call   2ad <main+0x2ad>
 2ad:	31 f6                	xor    %esi,%esi
 2af:	48 8d 2d 00 01 00 00 	lea    0x100(%rip),%rbp        # 3b6 <main+0x3b6>
 2b6:	48 8d 3d 76 00 00 00 	lea    0x76(%rip),%rdi        # 333 <main+0x333>
 2bd:	44 8b 4c b5 00       	mov    0x0(%rbp,%rsi,4),%r9d
 2c2:	45 8b 44 b4 18       	mov    0x18(%r12,%rsi,4),%r8d
 2c7:	89 f2                	mov    %esi,%edx
 2c9:	48 89 f9             	mov    %rdi,%rcx
 2cc:	e8 00 00 00 00       	call   2d1 <main+0x2d1>
 2d1:	48 83 c6 01          	add    $0x1,%rsi
 2d5:	48 83 fe 10          	cmp    $0x10,%rsi
 2d9:	75 e2                	jne    2bd <main+0x2bd>
 2db:	31 f6                	xor    %esi,%esi
 2dd:	48 8d 3d 80 00 00 00 	lea    0x80(%rip),%rdi        # 364 <main+0x364>
 2e4:	48 8d 2d 88 00 00 00 	lea    0x88(%rip),%rbp        # 373 <main+0x373>
 2eb:	48 8b 04 f7          	mov    (%rdi,%rsi,8),%rax
 2ef:	89 f2                	mov    %esi,%edx
 2f1:	48 89 e9             	mov    %rbp,%rcx
 2f4:	44 8b 48 0c          	mov    0xc(%rax),%r9d
 2f8:	44 8b 40 08          	mov    0x8(%rax),%r8d
 2fc:	e8 00 00 00 00       	call   301 <main+0x301>
 301:	48 83 c6 01          	add    $0x1,%rsi
 305:	48 83 fe 10          	cmp    $0x10,%rsi
 309:	75 e0                	jne    2eb <main+0x2eb>
 30b:	31 f6                	xor    %esi,%esi
 30d:	e9 30 ff ff ff       	jmp    242 <main+0x242>
 312:	4c 89 e0             	mov    %r12,%rax
 315:	0f 1f 00             	nopl   (%rax)
 318:	48 89 6c 24 40       	mov    %rbp,0x40(%rsp)
 31d:	4c 8d 35 00 00 00 00 	lea    0x0(%rip),%r14        # 324 <main+0x324>
 324:	4c 8d 3d 80 00 00 00 	lea    0x80(%rip),%r15        # 3ab <main+0x3ab>
 32b:	4c 89 64 24 48       	mov    %r12,0x48(%rsp)
 330:	41 8d 49 ff          	lea    -0x1(%r9),%ecx
 334:	45 31 c0             	xor    %r8d,%r8d
 337:	c1 e9 03             	shr    $0x3,%ecx
 33a:	45 85 c9             	test   %r9d,%r9d
 33d:	49 0f 44 c8          	cmove  %r8,%rcx
 341:	41 8b 2c 8e          	mov    (%r14,%rcx,4),%ebp
 345:	85 ed                	test   %ebp,%ebp
 347:	74 2f                	je     378 <main+0x378>
 349:	45 89 ec             	mov    %r13d,%r12d
 34c:	48 8d 48 08          	lea    0x8(%rax),%rcx
 350:	45 29 cc             	sub    %r9d,%r12d
 353:	eb 10                	jmp    365 <main+0x365>
 355:	0f 1f 00             	nopl   (%rax)
 358:	41 83 c0 01          	add    $0x1,%r8d
 35c:	48 83 c1 0c          	add    $0xc,%rcx
 360:	41 39 e8             	cmp    %ebp,%r8d
 363:	74 13                	je     378 <main+0x378>
 365:	39 51 04             	cmp    %edx,0x4(%rcx)
 368:	75 ee                	jne    358 <main+0x358>
 36a:	44 3b 21             	cmp    (%rcx),%r12d
 36d:	75 e9                	jne    358 <main+0x358>
 36f:	44 39 c5             	cmp    %r8d,%ebp
 372:	0f 85 e8 fe ff ff    	jne    260 <main+0x260>
 378:	8b 48 04             	mov    0x4(%rax),%ecx
 37b:	f6 c2 01             	test   $0x1,%dl
 37e:	0f 44 08             	cmove  (%rax),%ecx
 381:	85 c9                	test   %ecx,%ecx
 383:	74 41                	je     3c6 <main+0x3c6>
 385:	44 89 c8             	mov    %r9d,%eax
 388:	d1 ea                	shr    %edx
 38a:	41 83 c1 01          	add    $0x1,%r9d
 38e:	c1 e8 03             	shr    $0x3,%eax
 391:	0f af 0c 86          	imul   (%rsi,%rax,4),%ecx
 395:	49 03 0c c7          	add    (%r15,%rax,8),%rcx
 399:	48 89 c8             	mov    %rcx,%rax
 39c:	44 89 d1             	mov    %r10d,%ecx
 39f:	41 d1 ea             	shr    %r10d
 3a2:	c1 e1 1f             	shl    $0x1f,%ecx
 3a5:	09 ca                	or     %ecx,%edx
 3a7:	44 89 d9             	mov    %r11d,%ecx
 3aa:	41 d1 eb             	shr    %r11d
 3ad:	c1 e1 1f             	shl    $0x1f,%ecx
 3b0:	41 09 ca             	or     %ecx,%r10d
 3b3:	89 f9                	mov    %edi,%ecx
 3b5:	d1 ef                	shr    %edi
 3b7:	c1 e1 1f             	shl    $0x1f,%ecx
 3ba:	41 09 cb             	or     %ecx,%r11d
 3bd:	45 39 cd             	cmp    %r9d,%r13d
 3c0:	0f 83 6a ff ff ff    	jae    330 <main+0x330>
 3c6:	48 8b 6c 24 40       	mov    0x40(%rsp),%rbp
 3cb:	e9 5e fe ff ff       	jmp    22e <main+0x22e>
 3d0:	48 89 c6             	mov    %rax,%rsi
 3d3:	48 89 d9             	mov    %rbx,%rcx
 3d6:	e8 00 00 00 00       	call   3db <main+0x3db>
 3db:	48 89 f1             	mov    %rsi,%rcx
 3de:	e8 00 00 00 00       	call   3e3 <main+0x3e3>
 3e3:	90                   	nop
 3e4:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
 3eb:	00 00 00 00 
 3ef:	90                   	nop

00000000000003f0 <_GLOBAL__sub_I__Z5htonlj>:
 3f0:	48 8d 05 00 14 3b 00 	lea    0x3b1400(%rip),%rax        # 3b17f7 <BRAM_0+0x3f7>
 3f7:	66 0f 6f 25 b0 00 00 	movdqa 0xb0(%rip),%xmm4        # 4af <_GLOBAL__sub_I__Z5htonlj+0xbf>
 3fe:	00 
 3ff:	66 0f 6f 05 c0 00 00 	movdqa 0xc0(%rip),%xmm0        # 4c7 <_GLOBAL__sub_I__Z5htonlj+0xd7>
 406:	00 
 407:	66 0f 6f 0d d0 00 00 	movdqa 0xd0(%rip),%xmm1        # 4df <_GLOBAL__sub_I__Z5htonlj+0xef>
 40e:	00 
 40f:	66 0f 6f 15 e0 00 00 	movdqa 0xe0(%rip),%xmm2        # 4f7 <_GLOBAL__sub_I__Z5htonlj+0x107>
 416:	00 
 417:	48 8d 90 00 05 00 00 	lea    0x500(%rax),%rdx
 41e:	66 0f 6f 1d f0 00 00 	movdqa 0xf0(%rip),%xmm3        # 516 <_GLOBAL__sub_I__Z5htonlj+0x126>
 425:	00 
 426:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
 42d:	00 00 00 
 430:	0f 29 20             	movaps %xmm4,(%rax)
 433:	48 83 c0 50          	add    $0x50,%rax
 437:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 43b:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 43f:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 443:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 447:	48 39 d0             	cmp    %rdx,%rax
 44a:	75 e4                	jne    430 <_GLOBAL__sub_I__Z5htonlj+0x40>
 44c:	48 8d 15 00 b8 3a 00 	lea    0x3ab800(%rip),%rdx        # 3abc53 <BRAM_1+0x453>
 453:	48 8b 0d b8 00 00 00 	mov    0xb8(%rip),%rcx        # 512 <_GLOBAL__sub_I__Z5htonlj+0x122>
 45a:	4c 8d 82 00 5c 00 00 	lea    0x5c00(%rdx),%r8
 461:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
 468:	48 c7 02 00 00 00 00 	movq   $0x0,(%rdx)
 46f:	48 8d 42 08          	lea    0x8(%rdx),%rax
 473:	48 83 c2 5c          	add    $0x5c,%rdx
 477:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
 47e:	00 00 
 480:	48 89 08             	mov    %rcx,(%rax)
 483:	48 83 c0 0c          	add    $0xc,%rax
 487:	c7 40 fc 1f 00 00 00 	movl   $0x1f,-0x4(%rax)
 48e:	48 39 d0             	cmp    %rdx,%rax
 491:	75 ed                	jne    480 <_GLOBAL__sub_I__Z5htonlj+0x90>
 493:	49 39 c0             	cmp    %rax,%r8
 496:	74 05                	je     49d <_GLOBAL__sub_I__Z5htonlj+0xad>
 498:	48 89 c2             	mov    %rax,%rdx
 49b:	eb cb                	jmp    468 <_GLOBAL__sub_I__Z5htonlj+0x78>
 49d:	48 8d 15 00 18 29 00 	lea    0x291800(%rip),%rdx        # 291ca4 <BRAM_2+0x4a4>
 4a4:	4c 8d 82 00 a0 11 00 	lea    0x11a000(%rdx),%r8
 4ab:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
 4b0:	48 c7 02 00 00 00 00 	movq   $0x0,(%rdx)
 4b7:	48 8d 42 08          	lea    0x8(%rdx),%rax
 4bb:	48 81 c2 bc 00 00 00 	add    $0xbc,%rdx
 4c2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 4c8:	48 89 08             	mov    %rcx,(%rax)
 4cb:	48 83 c0 0c          	add    $0xc,%rax
 4cf:	c7 40 fc 1f 00 00 00 	movl   $0x1f,-0x4(%rax)
 4d6:	48 39 d0             	cmp    %rdx,%rax
 4d9:	75 ed                	jne    4c8 <_GLOBAL__sub_I__Z5htonlj+0xd8>
 4db:	49 39 c0             	cmp    %rax,%r8
 4de:	74 05                	je     4e5 <_GLOBAL__sub_I__Z5htonlj+0xf5>
 4e0:	48 89 c2             	mov    %rax,%rdx
 4e3:	eb cb                	jmp    4b0 <_GLOBAL__sub_I__Z5htonlj+0xc0>
 4e5:	48 8d 05 00 88 14 00 	lea    0x148800(%rip),%rax        # 148cec <BRAM_3+0x4ec>
 4ec:	4c 8d 80 00 90 14 00 	lea    0x149000(%rax),%r8
 4f3:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
 4f8:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
 4ff:	48 8d 50 08          	lea    0x8(%rax),%rdx
 503:	48 05 bc 00 00 00    	add    $0xbc,%rax
 509:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
 510:	48 89 0a             	mov    %rcx,(%rdx)
 513:	48 83 c2 0c          	add    $0xc,%rdx
 517:	c7 42 fc 1f 00 00 00 	movl   $0x1f,-0x4(%rdx)
 51e:	48 39 d0             	cmp    %rdx,%rax
 521:	75 ed                	jne    510 <_GLOBAL__sub_I__Z5htonlj+0x120>
 523:	4c 39 c0             	cmp    %r8,%rax
 526:	75 d0                	jne    4f8 <_GLOBAL__sub_I__Z5htonlj+0x108>
 528:	48 8d 05 00 c8 06 00 	lea    0x6c800(%rip),%rax        # 6cd2f <BRAM_4+0x52f>
 52f:	4c 8d 80 00 c0 0d 00 	lea    0xdc000(%rax),%r8
 536:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
 53d:	00 00 00 
 540:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
 547:	48 8d 50 08          	lea    0x8(%rax),%rdx
 54b:	48 05 b0 00 00 00    	add    $0xb0,%rax
 551:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
 558:	48 89 0a             	mov    %rcx,(%rdx)
 55b:	48 83 c2 0c          	add    $0xc,%rdx
 55f:	c7 42 fc 1f 00 00 00 	movl   $0x1f,-0x4(%rdx)
 566:	48 39 d0             	cmp    %rdx,%rax
 569:	75 ed                	jne    558 <_GLOBAL__sub_I__Z5htonlj+0x168>
 56b:	49 39 c0             	cmp    %rax,%r8
 56e:	75 d0                	jne    540 <_GLOBAL__sub_I__Z5htonlj+0x150>
 570:	48 8d 05 00 c8 00 00 	lea    0xc800(%rip),%rax        # cd77 <BRAM_5+0x577>
 577:	4c 8d 80 00 00 06 00 	lea    0x60000(%rax),%r8
 57e:	66 90                	xchg   %ax,%ax
 580:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
 587:	48 8d 50 08          	lea    0x8(%rax),%rdx
 58b:	48 83 e8 80          	sub    $0xffffffffffffff80,%rax
 58f:	90                   	nop
 590:	48 89 0a             	mov    %rcx,(%rdx)
 593:	48 83 c2 0c          	add    $0xc,%rdx
 597:	c7 42 fc 1f 00 00 00 	movl   $0x1f,-0x4(%rdx)
 59e:	48 39 d0             	cmp    %rdx,%rax
 5a1:	75 ed                	jne    590 <_GLOBAL__sub_I__Z5htonlj+0x1a0>
 5a3:	4c 39 c0             	cmp    %r8,%rax
 5a6:	75 d8                	jne    580 <_GLOBAL__sub_I__Z5htonlj+0x190>
 5a8:	48 8d 05 00 b4 00 00 	lea    0xb400(%rip),%rax        # b9af <BRAM_6+0x5af>
 5af:	48 8d 90 00 14 00 00 	lea    0x1400(%rax),%rdx
 5b6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
 5bd:	00 00 00 
 5c0:	0f 29 20             	movaps %xmm4,(%rax)
 5c3:	48 83 c0 50          	add    $0x50,%rax
 5c7:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 5cb:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 5cf:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 5d3:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 5d7:	48 39 c2             	cmp    %rax,%rdx
 5da:	75 e4                	jne    5c0 <_GLOBAL__sub_I__Z5htonlj+0x1d0>
 5dc:	48 8d 05 00 a0 00 00 	lea    0xa000(%rip),%rax        # a5e3 <BRAM_7+0x5e3>
 5e3:	48 8d 90 00 14 00 00 	lea    0x1400(%rax),%rdx
 5ea:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 5f0:	0f 29 20             	movaps %xmm4,(%rax)
 5f3:	48 83 c0 50          	add    $0x50,%rax
 5f7:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 5fb:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 5ff:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 603:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 607:	48 39 c2             	cmp    %rax,%rdx
 60a:	75 e4                	jne    5f0 <_GLOBAL__sub_I__Z5htonlj+0x200>
 60c:	48 8d 05 00 8c 00 00 	lea    0x8c00(%rip),%rax        # 9213 <BRAM_8+0x613>
 613:	48 8d 90 00 14 00 00 	lea    0x1400(%rax),%rdx
 61a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 620:	0f 29 20             	movaps %xmm4,(%rax)
 623:	48 83 c0 50          	add    $0x50,%rax
 627:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 62b:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 62f:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 633:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 637:	48 39 d0             	cmp    %rdx,%rax
 63a:	75 e4                	jne    620 <_GLOBAL__sub_I__Z5htonlj+0x230>
 63c:	48 8d 05 00 78 00 00 	lea    0x7800(%rip),%rax        # 7e43 <BRAM_9+0x643>
 643:	48 8d 90 00 14 00 00 	lea    0x1400(%rax),%rdx
 64a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 650:	0f 29 20             	movaps %xmm4,(%rax)
 653:	48 83 c0 50          	add    $0x50,%rax
 657:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 65b:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 65f:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 663:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 667:	48 39 c2             	cmp    %rax,%rdx
 66a:	75 e4                	jne    650 <_GLOBAL__sub_I__Z5htonlj+0x260>
 66c:	48 8d 05 00 64 00 00 	lea    0x6400(%rip),%rax        # 6a73 <BRAM_a+0x673>
 673:	48 8d 90 00 14 00 00 	lea    0x1400(%rax),%rdx
 67a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 680:	0f 29 20             	movaps %xmm4,(%rax)
 683:	48 83 c0 50          	add    $0x50,%rax
 687:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 68b:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 68f:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 693:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 697:	48 39 c2             	cmp    %rax,%rdx
 69a:	75 e4                	jne    680 <_GLOBAL__sub_I__Z5htonlj+0x290>
 69c:	48 8d 05 00 50 00 00 	lea    0x5000(%rip),%rax        # 56a3 <BRAM_b+0x6a3>
 6a3:	48 8d 90 00 14 00 00 	lea    0x1400(%rax),%rdx
 6aa:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 6b0:	0f 29 20             	movaps %xmm4,(%rax)
 6b3:	48 83 c0 50          	add    $0x50,%rax
 6b7:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 6bb:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 6bf:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 6c3:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 6c7:	48 39 d0             	cmp    %rdx,%rax
 6ca:	75 e4                	jne    6b0 <_GLOBAL__sub_I__Z5htonlj+0x2c0>
 6cc:	48 8d 05 00 3c 00 00 	lea    0x3c00(%rip),%rax        # 42d3 <BRAM_c+0x6d3>
 6d3:	48 8d 90 00 14 00 00 	lea    0x1400(%rax),%rdx
 6da:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 6e0:	0f 29 20             	movaps %xmm4,(%rax)
 6e3:	48 83 c0 50          	add    $0x50,%rax
 6e7:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 6eb:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 6ef:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 6f3:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 6f7:	48 39 c2             	cmp    %rax,%rdx
 6fa:	75 e4                	jne    6e0 <_GLOBAL__sub_I__Z5htonlj+0x2f0>
 6fc:	48 8d 05 00 28 00 00 	lea    0x2800(%rip),%rax        # 2f03 <BRAM_d+0x703>
 703:	48 8d 90 00 14 00 00 	lea    0x1400(%rax),%rdx
 70a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 710:	0f 29 20             	movaps %xmm4,(%rax)
 713:	48 83 c0 50          	add    $0x50,%rax
 717:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 71b:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 71f:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 723:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 727:	48 39 d0             	cmp    %rdx,%rax
 72a:	75 e4                	jne    710 <_GLOBAL__sub_I__Z5htonlj+0x320>
 72c:	48 8d 05 00 14 00 00 	lea    0x1400(%rip),%rax        # 1b33 <BRAM_e+0x733>
 733:	48 8d 90 00 14 00 00 	lea    0x1400(%rax),%rdx
 73a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 740:	0f 29 20             	movaps %xmm4,(%rax)
 743:	48 83 c0 50          	add    $0x50,%rax
 747:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 74b:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 74f:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 753:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 757:	48 39 d0             	cmp    %rdx,%rax
 75a:	75 e4                	jne    740 <_GLOBAL__sub_I__Z5htonlj+0x350>
 75c:	48 8d 05 00 00 00 00 	lea    0x0(%rip),%rax        # 763 <_GLOBAL__sub_I__Z5htonlj+0x373>
 763:	48 8d 90 00 14 00 00 	lea    0x1400(%rax),%rdx
 76a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
 770:	0f 29 20             	movaps %xmm4,(%rax)
 773:	48 83 c0 50          	add    $0x50,%rax
 777:	0f 29 40 c0          	movaps %xmm0,-0x40(%rax)
 77b:	0f 29 48 d0          	movaps %xmm1,-0x30(%rax)
 77f:	0f 29 50 e0          	movaps %xmm2,-0x20(%rax)
 783:	0f 29 58 f0          	movaps %xmm3,-0x10(%rax)
 787:	48 39 d0             	cmp    %rdx,%rax
 78a:	75 e4                	jne    770 <_GLOBAL__sub_I__Z5htonlj+0x380>
 78c:	c3                   	ret
 78d:	90                   	nop
 78e:	90                   	nop
 78f:	90                   	nop
