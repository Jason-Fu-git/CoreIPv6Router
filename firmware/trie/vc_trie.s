
vc_trie.o:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <VCTrieInsert>:
   0:	fe010113          	addi	sp,sp,-32
   4:	00112e23          	sw	ra,28(sp)
   8:	00812c23          	sw	s0,24(sp)
   c:	00912a23          	sw	s1,20(sp)
  10:	01212823          	sw	s2,16(sp)
  14:	01312623          	sw	s3,12(sp)
  18:	01412423          	sw	s4,8(sp)
  1c:	01c00793          	li	a5,28
  20:	00052303          	lw	t1,0(a0)
  24:	00452e83          	lw	t4,4(a0)
  28:	00852e03          	lw	t3,8(a0)
  2c:	00c52f83          	lw	t6,12(a0)
  30:	36b7f463          	bgeu	a5,a1,398 <.L53>
  34:	000007b7          	lui	a5,0x0
  38:	000004b7          	lui	s1,0x0
  3c:	fe458f13          	addi	t5,a1,-28
  40:	00078413          	mv	s0,a5
  44:	00078893          	mv	a7,a5
  48:	00000393          	li	t2,0
  4c:	00048493          	mv	s1,s1
  50:	208002b7          	lui	t0,0x20800
  54:	0840006f          	j	d8 <.L13>

00000058 <.L55>:
  58:	0048a803          	lw	a6,4(a7)
  5c:	08081863          	bnez	a6,ec <.L41>
  60:	00470793          	addi	a5,a4,4
  64:	00279793          	slli	a5,a5,0x2
  68:	00f407b3          	add	a5,s0,a5
  6c:	01442903          	lw	s2,20(s0)
  70:	0087a803          	lw	a6,8(a5) # 8 <VCTrieInsert+0x8>
  74:	00271693          	slli	a3,a4,0x2
  78:	00d486b3          	add	a3,s1,a3
  7c:	0406a983          	lw	s3,64(a3)
  80:	00190913          	addi	s2,s2,1
  84:	00180813          	addi	a6,a6,1
  88:	01242a23          	sw	s2,20(s0)
  8c:	0107a423          	sw	a6,8(a5)
  90:	0b387a63          	bgeu	a6,s3,144 <.L25>
  94:	01871713          	slli	a4,a4,0x18
  98:	0108a223          	sw	a6,4(a7)
  9c:	00570733          	add	a4,a4,t0

000000a0 <.L11>:
  a0:	01fe9a13          	slli	s4,t4,0x1f
  a4:	01fe1993          	slli	s3,t3,0x1f
  a8:	01ff9913          	slli	s2,t6,0x1f
  ac:	00481793          	slli	a5,a6,0x4
  b0:	00135313          	srli	t1,t1,0x1
  b4:	001ede93          	srli	t4,t4,0x1
  b8:	001e5e13          	srli	t3,t3,0x1
  bc:	00138393          	addi	t2,t2,1
  c0:	00e788b3          	add	a7,a5,a4
  c4:	01436333          	or	t1,t1,s4
  c8:	013eeeb3          	or	t4,t4,s3
  cc:	012e6e33          	or	t3,t3,s2
  d0:	001fdf93          	srli	t6,t6,0x1
  d4:	11e38c63          	beq	t2,t5,1ec <.L54>

000000d8 <.L13>:
  d8:	00137793          	andi	a5,t1,1
  dc:	0033d713          	srli	a4,t2,0x3
  e0:	f6079ce3          	bnez	a5,58 <.L55>
  e4:	0008a803          	lw	a6,0(a7)
  e8:	00080863          	beqz	a6,f8 <.L56>

000000ec <.L41>:
  ec:	01871713          	slli	a4,a4,0x18
  f0:	00570733          	add	a4,a4,t0
  f4:	fadff06f          	j	a0 <.L11>

000000f8 <.L56>:
  f8:	00470793          	addi	a5,a4,4
  fc:	00279793          	slli	a5,a5,0x2
 100:	00f407b3          	add	a5,s0,a5
 104:	01442903          	lw	s2,20(s0)
 108:	0087a803          	lw	a6,8(a5)
 10c:	00271693          	slli	a3,a4,0x2
 110:	00d486b3          	add	a3,s1,a3
 114:	0406a983          	lw	s3,64(a3)
 118:	00190913          	addi	s2,s2,1
 11c:	00180813          	addi	a6,a6,1
 120:	01242a23          	sw	s2,20(s0)
 124:	0107a423          	sw	a6,8(a5)
 128:	01387e63          	bgeu	a6,s3,144 <.L25>
 12c:	01871713          	slli	a4,a4,0x18
 130:	0108a023          	sw	a6,0(a7)
 134:	00570733          	add	a4,a4,t0
 138:	f69ff06f          	j	a0 <.L11>

0000013c <.L35>:
 13c:	00000813          	li	a6,0

00000140 <.L15>:
 140:	21e5f863          	bgeu	a1,t5,350 <.L57>

00000144 <.L25>:
 144:	00058913          	mv	s2,a1
 148:	00050793          	mv	a5,a0
 14c:	00052703          	lw	a4,0(a0)
 150:	00070513          	mv	a0,a4
 154:	69855513          	0x69855513
 158:	00050613          	mv	a2,a0
 15c:	0047a703          	lw	a4,4(a5)
 160:	00070513          	mv	a0,a4
 164:	69855513          	0x69855513
 168:	00050693          	mv	a3,a0
 16c:	0087a703          	lw	a4,8(a5)
 170:	00070513          	mv	a0,a4
 174:	69855513          	0x69855513
 178:	00050713          	mv	a4,a0
 17c:	00c7a783          	lw	a5,12(a5)
 180:	00078513          	mv	a0,a5
 184:	69855513          	0x69855513
 188:	00050793          	mv	a5,a0
 18c:	000005b7          	lui	a1,0x0
 190:	05c40493          	addi	s1,s0,92
 194:	00058593          	mv	a1,a1
 198:	00048513          	mv	a0,s1
 19c:	00000097          	auipc	ra,0x0
 1a0:	000080e7          	jalr	ra # 19c <.L25+0x58>
 1a4:	00000537          	lui	a0,0x0
 1a8:	00090613          	mv	a2,s2
 1ac:	00048593          	mv	a1,s1
 1b0:	00050513          	mv	a0,a0
 1b4:	00000097          	auipc	ra,0x0
 1b8:	000080e7          	jalr	ra # 1b4 <.L25+0x70>
 1bc:	05842783          	lw	a5,88(s0)
 1c0:	01c12083          	lw	ra,28(sp)
 1c4:	01412483          	lw	s1,20(sp)
 1c8:	00178793          	addi	a5,a5,1
 1cc:	04f42c23          	sw	a5,88(s0)
 1d0:	01812403          	lw	s0,24(sp)
 1d4:	01012903          	lw	s2,16(sp)
 1d8:	00c12983          	lw	s3,12(sp)
 1dc:	00812a03          	lw	s4,8(sp)
 1e0:	00100513          	li	a0,1
 1e4:	02010113          	addi	sp,sp,32
 1e8:	00008067          	ret

000001ec <.L54>:
 1ec:	f5e5ece3          	bltu	a1,t5,144 <.L25>
 1f0:	003f5793          	srli	a5,t5,0x3
 1f4:	00000737          	lui	a4,0x0
 1f8:	00279693          	slli	a3,a5,0x2
 1fc:	00070713          	mv	a4,a4
 200:	00d70733          	add	a4,a4,a3
 204:	00072903          	lw	s2,0(a4) # 0 <VCTrieInsert>

00000208 <.L2>:
 208:	000002b7          	lui	t0,0x0
 20c:	01e00493          	li	s1,30
 210:	00028293          	mv	t0,t0
 214:	208003b7          	lui	t2,0x20800

00000218 <.L24>:
 218:	04090263          	beqz	s2,25c <.L14>
 21c:	0088a703          	lw	a4,8(a7)
 220:	f0e4eee3          	bltu	s1,a4,13c <.L35>
 224:	0108a703          	lw	a4,16(a7)
 228:	f0e4eae3          	bltu	s1,a4,13c <.L35>
 22c:	01488693          	addi	a3,a7,20
 230:	00000713          	li	a4,0

00000234 <.L16>:
 234:	00170713          	addi	a4,a4,1
 238:	00070813          	mv	a6,a4
 23c:	03270063          	beq	a4,s2,25c <.L14>
 240:	00c68693          	addi	a3,a3,12
 244:	ff46a983          	lw	s3,-12(a3)
 248:	ef34ece3          	bltu	s1,s3,140 <.L15>
 24c:	ffc6a983          	lw	s3,-4(a3)
 250:	ff34f2e3          	bgeu	s1,s3,234 <.L16>
 254:	0fe5fe63          	bgeu	a1,t5,350 <.L57>
 258:	eedff06f          	j	144 <.L25>

0000025c <.L14>:
 25c:	00137713          	andi	a4,t1,1
 260:	06070063          	beqz	a4,2c0 <.L58>
 264:	0048a683          	lw	a3,4(a7)
 268:	0a068263          	beqz	a3,30c <.L59>

0000026c <.L43>:
 26c:	01879793          	slli	a5,a5,0x18
 270:	007787b3          	add	a5,a5,t2

00000274 <.L23>:
 274:	01fe9a13          	slli	s4,t4,0x1f
 278:	01fe1993          	slli	s3,t3,0x1f
 27c:	01ff9913          	slli	s2,t6,0x1f
 280:	00469713          	slli	a4,a3,0x4
 284:	00135313          	srli	t1,t1,0x1
 288:	001ede93          	srli	t4,t4,0x1
 28c:	001e5e13          	srli	t3,t3,0x1
 290:	001f0f13          	addi	t5,t5,1
 294:	00f708b3          	add	a7,a4,a5
 298:	01436333          	or	t1,t1,s4
 29c:	013eeeb3          	or	t4,t4,s3
 2a0:	012e6e33          	or	t3,t3,s2
 2a4:	001fdf93          	srli	t6,t6,0x1
 2a8:	e9e5eee3          	bltu	a1,t5,144 <.L25>
 2ac:	003f5793          	srli	a5,t5,0x3
 2b0:	00279713          	slli	a4,a5,0x2
 2b4:	00e28733          	add	a4,t0,a4
 2b8:	00072903          	lw	s2,0(a4)
 2bc:	f5dff06f          	j	218 <.L24>

000002c0 <.L58>:
 2c0:	0008a683          	lw	a3,0(a7)
 2c4:	fa0694e3          	bnez	a3,26c <.L43>
 2c8:	00478713          	addi	a4,a5,4
 2cc:	00271713          	slli	a4,a4,0x2
 2d0:	00e40733          	add	a4,s0,a4
 2d4:	01442803          	lw	a6,20(s0)
 2d8:	00872683          	lw	a3,8(a4)
 2dc:	00279913          	slli	s2,a5,0x2
 2e0:	01228933          	add	s2,t0,s2
 2e4:	04092903          	lw	s2,64(s2)
 2e8:	00180813          	addi	a6,a6,1
 2ec:	00168693          	addi	a3,a3,1
 2f0:	01042a23          	sw	a6,20(s0)
 2f4:	00d72423          	sw	a3,8(a4)
 2f8:	e526f6e3          	bgeu	a3,s2,144 <.L25>
 2fc:	01879793          	slli	a5,a5,0x18
 300:	00d8a023          	sw	a3,0(a7)
 304:	007787b3          	add	a5,a5,t2
 308:	f6dff06f          	j	274 <.L23>

0000030c <.L59>:
 30c:	00478713          	addi	a4,a5,4
 310:	00271713          	slli	a4,a4,0x2
 314:	00e40733          	add	a4,s0,a4
 318:	01442803          	lw	a6,20(s0)
 31c:	00872683          	lw	a3,8(a4)
 320:	00279913          	slli	s2,a5,0x2
 324:	01228933          	add	s2,t0,s2
 328:	04092903          	lw	s2,64(s2)
 32c:	00180813          	addi	a6,a6,1
 330:	00168693          	addi	a3,a3,1
 334:	01042a23          	sw	a6,20(s0)
 338:	00d72423          	sw	a3,8(a4)
 33c:	e126f4e3          	bgeu	a3,s2,144 <.L25>
 340:	01879793          	slli	a5,a5,0x18
 344:	00d8a223          	sw	a3,4(a7)
 348:	007787b3          	add	a5,a5,t2
 34c:	f29ff06f          	j	274 <.L23>

00000350 <.L57>:
 350:	00181793          	slli	a5,a6,0x1
 354:	01078833          	add	a6,a5,a6
 358:	01c12083          	lw	ra,28(sp)
 35c:	01812403          	lw	s0,24(sp)
 360:	00888793          	addi	a5,a7,8
 364:	00281813          	slli	a6,a6,0x2
 368:	010787b3          	add	a5,a5,a6
 36c:	41e58f33          	sub	t5,a1,t5
 370:	01e7a023          	sw	t5,0(a5)
 374:	0067a223          	sw	t1,4(a5)
 378:	00c7a423          	sw	a2,8(a5)
 37c:	01412483          	lw	s1,20(sp)
 380:	01012903          	lw	s2,16(sp)
 384:	00c12983          	lw	s3,12(sp)
 388:	00812a03          	lw	s4,8(sp)
 38c:	00000513          	li	a0,0
 390:	02010113          	addi	sp,sp,32
 394:	00008067          	ret

00000398 <.L53>:
 398:	000007b7          	lui	a5,0x0
 39c:	00078413          	mv	s0,a5
 3a0:	00078893          	mv	a7,a5
 3a4:	00000913          	li	s2,0
 3a8:	00000f13          	li	t5,0
 3ac:	00000793          	li	a5,0
 3b0:	e59ff06f          	j	208 <.L2>

000003b4 <VCTrieLookup>:
 3b4:	01c00713          	li	a4,28
 3b8:	00052783          	lw	a5,0(a0) # 0 <VCTrieInsert>
 3bc:	00452603          	lw	a2,4(a0)
 3c0:	00852683          	lw	a3,8(a0)
 3c4:	00c52303          	lw	t1,12(a0)
 3c8:	18b77663          	bgeu	a4,a1,554 <.L99>
 3cc:	00000737          	lui	a4,0x0
 3d0:	fe458893          	addi	a7,a1,-28 # ffffffe4 <VCEntryInvalidate+0xfffffa1c>
 3d4:	00070813          	mv	a6,a4
 3d8:	00000e93          	li	t4,0
 3dc:	20800fb7          	lui	t6,0x20800
 3e0:	0480006f          	j	428 <.L68>

000003e4 <.L101>:
 3e4:	00482e03          	lw	t3,4(a6)
 3e8:	01f50733          	add	a4,a0,t6
 3ec:	040e0c63          	beqz	t3,444 <.L83>

000003f0 <.L79>:
 3f0:	01f61293          	slli	t0,a2,0x1f
 3f4:	01f69f13          	slli	t5,a3,0x1f
 3f8:	01f31513          	slli	a0,t1,0x1f
 3fc:	004e1813          	slli	a6,t3,0x4
 400:	0017d793          	srli	a5,a5,0x1
 404:	00165613          	srli	a2,a2,0x1
 408:	0016d693          	srli	a3,a3,0x1
 40c:	001e8e93          	addi	t4,t4,1
 410:	00e80833          	add	a6,a6,a4
 414:	0057e7b3          	or	a5,a5,t0
 418:	01e66633          	or	a2,a2,t5
 41c:	00a6e6b3          	or	a3,a3,a0
 420:	00135313          	srli	t1,t1,0x1
 424:	031e8463          	beq	t4,a7,44c <.L100>

00000428 <.L68>:
 428:	003ed513          	srli	a0,t4,0x3
 42c:	0017ff13          	andi	t5,a5,1
 430:	01851513          	slli	a0,a0,0x18
 434:	00082e03          	lw	t3,0(a6)
 438:	fa0f16e3          	bnez	t5,3e4 <.L101>
 43c:	01f50733          	add	a4,a0,t6
 440:	fa0e18e3          	bnez	t3,3f0 <.L79>

00000444 <.L83>:
 444:	00000513          	li	a0,0
 448:	00008067          	ret

0000044c <.L100>:
 44c:	ff15ece3          	bltu	a1,a7,444 <.L83>
 450:	0038d713          	srli	a4,a7,0x3
 454:	00000537          	lui	a0,0x0
 458:	00271e13          	slli	t3,a4,0x2
 45c:	00050513          	mv	a0,a0
 460:	01c50533          	add	a0,a0,t3
 464:	00052f03          	lw	t5,0(a0) # 0 <VCTrieInsert>

00000468 <.L61>:
 468:	ff010113          	addi	sp,sp,-16
 46c:	000002b7          	lui	t0,0x0
 470:	00812623          	sw	s0,12(sp)
 474:	00912423          	sw	s1,8(sp)
 478:	20800fb7          	lui	t6,0x20800
 47c:	00028293          	mv	t0,t0

00000480 <.L75>:
 480:	040f0a63          	beqz	t5,4d4 <.L69>
 484:	00880513          	addi	a0,a6,8
 488:	00050e13          	mv	t3,a0
 48c:	00000e93          	li	t4,0
 490:	411583b3          	sub	t2,a1,a7
 494:	00c0006f          	j	4a0 <.L72>

00000498 <.L70>:
 498:	001e8e93          	addi	t4,t4,1
 49c:	03df0c63          	beq	t5,t4,4d4 <.L69>

000004a0 <.L72>:
 4a0:	004e2483          	lw	s1,4(t3)
 4a4:	000e2403          	lw	s0,0(t3)
 4a8:	00ce0e13          	addi	t3,t3,12
 4ac:	fef496e3          	bne	s1,a5,498 <.L70>
 4b0:	fe7414e3          	bne	s0,t2,498 <.L70>
 4b4:	00c12403          	lw	s0,12(sp)
 4b8:	001e9793          	slli	a5,t4,0x1
 4bc:	01d78eb3          	add	t4,a5,t4
 4c0:	002e9e93          	slli	t4,t4,0x2
 4c4:	00812483          	lw	s1,8(sp)
 4c8:	01d50533          	add	a0,a0,t4
 4cc:	01010113          	addi	sp,sp,16
 4d0:	00008067          	ret

000004d4 <.L69>:
 4d4:	0017fe13          	andi	t3,a5,1
 4d8:	00082503          	lw	a0,0(a6)
 4dc:	060e0063          	beqz	t3,53c <.L102>
 4e0:	00482503          	lw	a0,4(a6)
 4e4:	04050e63          	beqz	a0,540 <.L86>

000004e8 <.L94>:
 4e8:	01871713          	slli	a4,a4,0x18
 4ec:	01f61f13          	slli	t5,a2,0x1f
 4f0:	01f69e93          	slli	t4,a3,0x1f
 4f4:	01f31e13          	slli	t3,t1,0x1f
 4f8:	01f70733          	add	a4,a4,t6
 4fc:	00451813          	slli	a6,a0,0x4
 500:	0017d793          	srli	a5,a5,0x1
 504:	00165613          	srli	a2,a2,0x1
 508:	0016d693          	srli	a3,a3,0x1
 50c:	00188893          	addi	a7,a7,1
 510:	00e80833          	add	a6,a6,a4
 514:	01e7e7b3          	or	a5,a5,t5
 518:	01d66633          	or	a2,a2,t4
 51c:	01c6e6b3          	or	a3,a3,t3
 520:	00135313          	srli	t1,t1,0x1
 524:	0115ee63          	bltu	a1,a7,540 <.L86>
 528:	0038d713          	srli	a4,a7,0x3
 52c:	00271513          	slli	a0,a4,0x2
 530:	00a28533          	add	a0,t0,a0
 534:	00052f03          	lw	t5,0(a0)
 538:	f49ff06f          	j	480 <.L75>

0000053c <.L102>:
 53c:	fa0516e3          	bnez	a0,4e8 <.L94>

00000540 <.L86>:
 540:	00c12403          	lw	s0,12(sp)
 544:	00812483          	lw	s1,8(sp)
 548:	00000513          	li	a0,0
 54c:	01010113          	addi	sp,sp,16
 550:	00008067          	ret

00000554 <.L99>:
 554:	00000737          	lui	a4,0x0
 558:	00070813          	mv	a6,a4
 55c:	00000f13          	li	t5,0
 560:	00000893          	li	a7,0
 564:	00000713          	li	a4,0
 568:	f01ff06f          	j	468 <.L61>

0000056c <VCTrieGetNodeCount>:
 56c:	000007b7          	lui	a5,0x0
 570:	0147a503          	lw	a0,20(a5) # 14 <VCTrieInsert+0x14>
 574:	00008067          	ret

00000578 <VCTrieGetExcessiveCount>:
 578:	000007b7          	lui	a5,0x0
 57c:	0587a503          	lw	a0,88(a5) # 58 <.L55>
 580:	00008067          	ret

00000584 <VCEntryIsValid>:
 584:	00052703          	lw	a4,0(a0)
 588:	01e00793          	li	a5,30
 58c:	00e7e863          	bltu	a5,a4,59c <.L107>
 590:	00852503          	lw	a0,8(a0)
 594:	01f53513          	sltiu	a0,a0,31
 598:	00008067          	ret

0000059c <.L107>:
 59c:	00000513          	li	a0,0
 5a0:	00008067          	ret

000005a4 <VCEntryIsInvalid>:
 5a4:	00052703          	lw	a4,0(a0)
 5a8:	01e00793          	li	a5,30
 5ac:	00e7ea63          	bltu	a5,a4,5c0 <.L110>
 5b0:	00852503          	lw	a0,8(a0)
 5b4:	01f53513          	sltiu	a0,a0,31
 5b8:	00154513          	xori	a0,a0,1
 5bc:	00008067          	ret

000005c0 <.L110>:
 5c0:	00100513          	li	a0,1
 5c4:	00008067          	ret

000005c8 <VCEntryInvalidate>:
 5c8:	01f00793          	li	a5,31
 5cc:	00f52023          	sw	a5,0(a0)
 5d0:	00f52423          	sw	a5,8(a0)
 5d4:	00008067          	ret

Disassembly of section .text.startup:

00000000 <_GLOBAL__sub_I_trie>:
   0:	000007b7          	lui	a5,0x0
   4:	00078793          	mv	a5,a5
   8:	01f00713          	li	a4,31
   c:	0007a023          	sw	zero,0(a5) # 0 <_GLOBAL__sub_I_trie>
  10:	0007a223          	sw	zero,4(a5)
  14:	00e7a423          	sw	a4,8(a5)
  18:	0007a623          	sw	zero,12(a5)
  1c:	00e7a823          	sw	a4,16(a5)
  20:	0007aa23          	sw	zero,20(a5)
  24:	0407ac23          	sw	zero,88(a5)
  28:	00008067          	ret
