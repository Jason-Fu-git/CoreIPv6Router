
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
  1c:	01512223          	sw	s5,4(sp)
  20:	01c00793          	li	a5,28
  24:	00052303          	lw	t1,0(a0)
  28:	00452e03          	lw	t3,4(a0)
  2c:	00852e83          	lw	t4,8(a0)
  30:	00c52f83          	lw	t6,12(a0)
  34:	36b7f463          	bgeu	a5,a1,39c <.L59>
  38:	000007b7          	lui	a5,0x0
  3c:	000009b7          	lui	s3,0x0
  40:	fe458f13          	addi	t5,a1,-28
  44:	00078413          	mv	s0,a5
  48:	00078893          	mv	a7,a5
  4c:	00000913          	li	s2,0
  50:	00098993          	mv	s3,s3
  54:	280004b7          	lui	s1,0x28000
  58:	04c0006f          	j	a4 <.L14>

0000005c <.L62>:
  5c:	0048a803          	lw	a6,4(a7)
  60:	14080463          	beqz	a6,1a8 <.L60>

00000064 <.L46>:
  64:	01771713          	slli	a4,a4,0x17
  68:	00976733          	or	a4,a4,s1

0000006c <.L12>:
  6c:	01fe1a13          	slli	s4,t3,0x1f
  70:	01fe9393          	slli	t2,t4,0x1f
  74:	01ff9293          	slli	t0,t6,0x1f
  78:	00a81793          	slli	a5,a6,0xa
  7c:	00135313          	srli	t1,t1,0x1
  80:	001e5e13          	srli	t3,t3,0x1
  84:	001ede93          	srli	t4,t4,0x1
  88:	00190913          	addi	s2,s2,1
  8c:	00e7e8b3          	or	a7,a5,a4
  90:	01436333          	or	t1,t1,s4
  94:	007e6e33          	or	t3,t3,t2
  98:	005eeeb3          	or	t4,t4,t0
  9c:	001fdf93          	srli	t6,t6,0x1
  a0:	15e90e63          	beq	s2,t5,1fc <.L61>

000000a4 <.L14>:
  a4:	00137793          	andi	a5,t1,1
  a8:	00395713          	srli	a4,s2,0x3
  ac:	fa0798e3          	bnez	a5,5c <.L62>
  b0:	0008a803          	lw	a6,0(a7)
  b4:	fa0818e3          	bnez	a6,64 <.L46>
  b8:	00870793          	addi	a5,a4,8
  bc:	00279393          	slli	t2,a5,0x2
  c0:	007403b3          	add	t2,s0,t2
  c4:	02042283          	lw	t0,32(s0)
  c8:	0043a683          	lw	a3,4(t2)
  cc:	00271813          	slli	a6,a4,0x2
  d0:	01098833          	add	a6,s3,a6
  d4:	04082a03          	lw	s4,64(a6)
  d8:	00128a93          	addi	s5,t0,1
  dc:	00168813          	addi	a6,a3,1
  e0:	03542023          	sw	s5,32(s0)
  e4:	0103a223          	sw	a6,4(t2)
  e8:	11486263          	bltu	a6,s4,1ec <.L55>

000000ec <.L33>:
  ec:	00279793          	slli	a5,a5,0x2
  f0:	00f407b3          	add	a5,s0,a5
  f4:	02542023          	sw	t0,32(s0)
  f8:	00d7a223          	sw	a3,4(a5) # 4 <VCTrieInsert+0x4>

000000fc <.L10>:
  fc:	00058913          	mv	s2,a1
 100:	00050613          	mv	a2,a0
 104:	00052783          	lw	a5,0(a0)
 108:	00078513          	mv	a0,a5
 10c:	69855513          	0x69855513
 110:	00050793          	mv	a5,a0
 114:	00462703          	lw	a4,4(a2)
 118:	00070513          	mv	a0,a4
 11c:	69855513          	0x69855513
 120:	00050713          	mv	a4,a0
 124:	00862683          	lw	a3,8(a2)
 128:	00068513          	mv	a0,a3
 12c:	69855513          	0x69855513
 130:	00050693          	mv	a3,a0
 134:	00c62603          	lw	a2,12(a2)
 138:	00060513          	mv	a0,a2
 13c:	69855513          	0x69855513
 140:	00050613          	mv	a2,a0
 144:	000005b7          	lui	a1,0x0
 148:	06840493          	addi	s1,s0,104
 14c:	00058593          	mv	a1,a1
 150:	00048513          	mv	a0,s1
 154:	00000097          	auipc	ra,0x0
 158:	000080e7          	jalr	ra # 154 <.L10+0x58>
 15c:	00000537          	lui	a0,0x0
 160:	00090613          	mv	a2,s2
 164:	00048593          	mv	a1,s1
 168:	00050513          	mv	a0,a0
 16c:	00000097          	auipc	ra,0x0
 170:	000080e7          	jalr	ra # 16c <.L10+0x70>
 174:	06442783          	lw	a5,100(s0)
 178:	00100513          	li	a0,1
 17c:	00178793          	addi	a5,a5,1
 180:	06f42223          	sw	a5,100(s0)

00000184 <.L1>:
 184:	01c12083          	lw	ra,28(sp)
 188:	01812403          	lw	s0,24(sp)
 18c:	01412483          	lw	s1,20(sp)
 190:	01012903          	lw	s2,16(sp)
 194:	00c12983          	lw	s3,12(sp)
 198:	00812a03          	lw	s4,8(sp)
 19c:	00412a83          	lw	s5,4(sp)
 1a0:	02010113          	addi	sp,sp,32
 1a4:	00008067          	ret

000001a8 <.L60>:
 1a8:	00870793          	addi	a5,a4,8
 1ac:	00279393          	slli	t2,a5,0x2
 1b0:	007403b3          	add	t2,s0,t2
 1b4:	02042283          	lw	t0,32(s0)
 1b8:	0043a683          	lw	a3,4(t2)
 1bc:	00271813          	slli	a6,a4,0x2
 1c0:	01098833          	add	a6,s3,a6
 1c4:	04082a03          	lw	s4,64(a6)
 1c8:	00128a93          	addi	s5,t0,1
 1cc:	00168813          	addi	a6,a3,1
 1d0:	03542023          	sw	s5,32(s0)
 1d4:	0103a223          	sw	a6,4(t2)
 1d8:	f1487ae3          	bgeu	a6,s4,ec <.L33>
 1dc:	01771713          	slli	a4,a4,0x17
 1e0:	0108a223          	sw	a6,4(a7)
 1e4:	00976733          	or	a4,a4,s1
 1e8:	e85ff06f          	j	6c <.L12>

000001ec <.L55>:
 1ec:	01771713          	slli	a4,a4,0x17
 1f0:	0108a023          	sw	a6,0(a7)
 1f4:	00976733          	or	a4,a4,s1
 1f8:	e75ff06f          	j	6c <.L12>

000001fc <.L61>:
 1fc:	f1e5e0e3          	bltu	a1,t5,fc <.L10>

00000200 <.L2>:
 200:	000002b7          	lui	t0,0x0
 204:	00028293          	mv	t0,t0
 208:	01e00493          	li	s1,30
 20c:	280003b7          	lui	t2,0x28000

00000210 <.L25>:
 210:	080f0863          	beqz	t5,2a0 <.L15>
 214:	ffff0793          	addi	a5,t5,-1
 218:	0037d793          	srli	a5,a5,0x3
 21c:	00279793          	slli	a5,a5,0x2
 220:	00f287b3          	add	a5,t0,a5
 224:	0007a783          	lw	a5,0(a5)
 228:	06078c63          	beqz	a5,2a0 <.L15>
 22c:	0108a703          	lw	a4,16(a7)
 230:	06e4e263          	bltu	s1,a4,294 <.L38>
 234:	0188a703          	lw	a4,24(a7)
 238:	04e4ee63          	bltu	s1,a4,294 <.L38>
 23c:	02088693          	addi	a3,a7,32
 240:	00000713          	li	a4,0

00000244 <.L17>:
 244:	00170713          	addi	a4,a4,1
 248:	00070813          	mv	a6,a4
 24c:	04f70a63          	beq	a4,a5,2a0 <.L15>
 250:	01068693          	addi	a3,a3,16
 254:	ff06a903          	lw	s2,-16(a3)
 258:	0324f663          	bgeu	s1,s2,284 <.L63>
 25c:	ebe5e0e3          	bltu	a1,t5,fc <.L10>

00000260 <.L64>:
 260:	01088793          	addi	a5,a7,16
 264:	00481813          	slli	a6,a6,0x4
 268:	010787b3          	add	a5,a5,a6
 26c:	41e58f33          	sub	t5,a1,t5
 270:	01e7a023          	sw	t5,0(a5)
 274:	0067a223          	sw	t1,4(a5)
 278:	00c7a423          	sw	a2,8(a5)
 27c:	00000513          	li	a0,0
 280:	f05ff06f          	j	184 <.L1>

00000284 <.L63>:
 284:	ff86a903          	lw	s2,-8(a3)
 288:	fb24fee3          	bgeu	s1,s2,244 <.L17>
 28c:	fde5fae3          	bgeu	a1,t5,260 <.L64>
 290:	e6dff06f          	j	fc <.L10>

00000294 <.L38>:
 294:	00000813          	li	a6,0
 298:	fde5f4e3          	bgeu	a1,t5,260 <.L64>
 29c:	e61ff06f          	j	fc <.L10>

000002a0 <.L15>:
 2a0:	00137713          	andi	a4,t1,1
 2a4:	003f5793          	srli	a5,t5,0x3
 2a8:	04070863          	beqz	a4,2f8 <.L65>
 2ac:	0048a683          	lw	a3,4(a7)
 2b0:	08068c63          	beqz	a3,348 <.L66>

000002b4 <.L49>:
 2b4:	01779793          	slli	a5,a5,0x17
 2b8:	0077e7b3          	or	a5,a5,t2

000002bc <.L24>:
 2bc:	01fe9893          	slli	a7,t4,0x1f
 2c0:	01fe1913          	slli	s2,t3,0x1f
 2c4:	01ff9813          	slli	a6,t6,0x1f
 2c8:	00135313          	srli	t1,t1,0x1
 2cc:	001e5e13          	srli	t3,t3,0x1
 2d0:	001ede93          	srli	t4,t4,0x1
 2d4:	00a69713          	slli	a4,a3,0xa
 2d8:	001f0f13          	addi	t5,t5,1
 2dc:	011e6e33          	or	t3,t3,a7
 2e0:	01236333          	or	t1,t1,s2
 2e4:	010eeeb3          	or	t4,t4,a6
 2e8:	001fdf93          	srli	t6,t6,0x1
 2ec:	00f768b3          	or	a7,a4,a5
 2f0:	f3e5f0e3          	bgeu	a1,t5,210 <.L25>
 2f4:	e09ff06f          	j	fc <.L10>

000002f8 <.L65>:
 2f8:	0008a683          	lw	a3,0(a7)
 2fc:	fa069ce3          	bnez	a3,2b4 <.L49>
 300:	00878813          	addi	a6,a5,8
 304:	00281713          	slli	a4,a6,0x2
 308:	00e40733          	add	a4,s0,a4
 30c:	02042983          	lw	s3,32(s0)
 310:	00472903          	lw	s2,4(a4)
 314:	00279693          	slli	a3,a5,0x2
 318:	00d286b3          	add	a3,t0,a3
 31c:	0406aa03          	lw	s4,64(a3)
 320:	00198a93          	addi	s5,s3,1 # 1 <VCTrieInsert+0x1>
 324:	00190693          	addi	a3,s2,1
 328:	03542023          	sw	s5,32(s0)
 32c:	00d72223          	sw	a3,4(a4)
 330:	0546ee63          	bltu	a3,s4,38c <.L67>

00000334 <.L30>:
 334:	00281793          	slli	a5,a6,0x2
 338:	00f407b3          	add	a5,s0,a5
 33c:	03342023          	sw	s3,32(s0)
 340:	0127a223          	sw	s2,4(a5)
 344:	db9ff06f          	j	fc <.L10>

00000348 <.L66>:
 348:	00878813          	addi	a6,a5,8
 34c:	00281713          	slli	a4,a6,0x2
 350:	00e40733          	add	a4,s0,a4
 354:	02042983          	lw	s3,32(s0)
 358:	00472903          	lw	s2,4(a4)
 35c:	00279693          	slli	a3,a5,0x2
 360:	00d286b3          	add	a3,t0,a3
 364:	0406aa03          	lw	s4,64(a3)
 368:	00198a93          	addi	s5,s3,1
 36c:	00190693          	addi	a3,s2,1
 370:	03542023          	sw	s5,32(s0)
 374:	00d72223          	sw	a3,4(a4)
 378:	fb46fee3          	bgeu	a3,s4,334 <.L30>
 37c:	01779793          	slli	a5,a5,0x17
 380:	00d8a223          	sw	a3,4(a7)
 384:	0077e7b3          	or	a5,a5,t2
 388:	f35ff06f          	j	2bc <.L24>

0000038c <.L67>:
 38c:	01779793          	slli	a5,a5,0x17
 390:	00d8a023          	sw	a3,0(a7)
 394:	0077e7b3          	or	a5,a5,t2
 398:	f25ff06f          	j	2bc <.L24>

0000039c <.L59>:
 39c:	000007b7          	lui	a5,0x0
 3a0:	00078413          	mv	s0,a5
 3a4:	00078893          	mv	a7,a5
 3a8:	00000f13          	li	t5,0
 3ac:	e55ff06f          	j	200 <.L2>

000003b0 <VCTrieLookup>:
 3b0:	01c00793          	li	a5,28
 3b4:	00052703          	lw	a4,0(a0) # 0 <VCTrieInsert>
 3b8:	00452683          	lw	a3,4(a0)
 3bc:	00852603          	lw	a2,8(a0)
 3c0:	00c52883          	lw	a7,12(a0)
 3c4:	16b7f863          	bgeu	a5,a1,534 <.L110>
 3c8:	000007b7          	lui	a5,0x0
 3cc:	fe458813          	addi	a6,a1,-28 # ffffffe4 <VCEntryInvalidate+0xfffffa44>
 3d0:	00078793          	mv	a5,a5
 3d4:	00000e93          	li	t4,0
 3d8:	28000fb7          	lui	t6,0x28000
 3dc:	0480006f          	j	424 <.L76>

000003e0 <.L112>:
 3e0:	0047a303          	lw	t1,4(a5) # 4 <VCTrieInsert+0x4>
 3e4:	01fe67b3          	or	a5,t3,t6
 3e8:	04030c63          	beqz	t1,440 <.L91>

000003ec <.L87>:
 3ec:	01f69f13          	slli	t5,a3,0x1f
 3f0:	01f61e13          	slli	t3,a2,0x1f
 3f4:	01f89513          	slli	a0,a7,0x1f
 3f8:	00a31313          	slli	t1,t1,0xa
 3fc:	00175713          	srli	a4,a4,0x1
 400:	0016d693          	srli	a3,a3,0x1
 404:	00165613          	srli	a2,a2,0x1
 408:	001e8e93          	addi	t4,t4,1
 40c:	00f367b3          	or	a5,t1,a5
 410:	01e76733          	or	a4,a4,t5
 414:	01c6e6b3          	or	a3,a3,t3
 418:	00a66633          	or	a2,a2,a0
 41c:	0018d893          	srli	a7,a7,0x1
 420:	03d80463          	beq	a6,t4,448 <.L111>

00000424 <.L76>:
 424:	003ede13          	srli	t3,t4,0x3
 428:	00177f13          	andi	t5,a4,1
 42c:	017e1e13          	slli	t3,t3,0x17
 430:	0007a303          	lw	t1,0(a5)
 434:	fa0f16e3          	bnez	t5,3e0 <.L112>
 438:	01fe67b3          	or	a5,t3,t6
 43c:	fa0318e3          	bnez	t1,3ec <.L87>

00000440 <.L91>:
 440:	00000513          	li	a0,0
 444:	00008067          	ret

00000448 <.L111>:
 448:	ff05ece3          	bltu	a1,a6,440 <.L91>

0000044c <.L69>:
 44c:	ff010113          	addi	sp,sp,-16
 450:	00000fb7          	lui	t6,0x0
 454:	00812623          	sw	s0,12(sp)
 458:	000f8f93          	mv	t6,t6
 45c:	28000f37          	lui	t5,0x28000

00000460 <.L83>:
 460:	06080063          	beqz	a6,4c0 <.L77>
 464:	fff80513          	addi	a0,a6,-1
 468:	00355513          	srli	a0,a0,0x3
 46c:	00251513          	slli	a0,a0,0x2
 470:	00af8533          	add	a0,t6,a0
 474:	00052e83          	lw	t4,0(a0)
 478:	040e8463          	beqz	t4,4c0 <.L77>
 47c:	01078513          	addi	a0,a5,16
 480:	00050313          	mv	t1,a0
 484:	00000e13          	li	t3,0
 488:	410582b3          	sub	t0,a1,a6
 48c:	00c0006f          	j	498 <.L80>

00000490 <.L78>:
 490:	001e0e13          	addi	t3,t3,1
 494:	03de0663          	beq	t3,t4,4c0 <.L77>

00000498 <.L80>:
 498:	00432403          	lw	s0,4(t1)
 49c:	00032383          	lw	t2,0(t1)
 4a0:	01030313          	addi	t1,t1,16
 4a4:	fee416e3          	bne	s0,a4,490 <.L78>
 4a8:	fe5394e3          	bne	t2,t0,490 <.L78>
 4ac:	00c12403          	lw	s0,12(sp)
 4b0:	004e1e13          	slli	t3,t3,0x4
 4b4:	01c50533          	add	a0,a0,t3
 4b8:	01010113          	addi	sp,sp,16
 4bc:	00008067          	ret

000004c0 <.L77>:
 4c0:	00177313          	andi	t1,a4,1
 4c4:	0007a503          	lw	a0,0(a5)
 4c8:	06030063          	beqz	t1,528 <.L113>
 4cc:	0047a503          	lw	a0,4(a5)
 4d0:	04050463          	beqz	a0,518 <.L93>

000004d4 <.L104>:
 4d4:	00385793          	srli	a5,a6,0x3
 4d8:	01779793          	slli	a5,a5,0x17
 4dc:	01f69e93          	slli	t4,a3,0x1f
 4e0:	01f61e13          	slli	t3,a2,0x1f
 4e4:	01f89313          	slli	t1,a7,0x1f
 4e8:	01e7e7b3          	or	a5,a5,t5
 4ec:	00175713          	srli	a4,a4,0x1
 4f0:	0016d693          	srli	a3,a3,0x1
 4f4:	00165613          	srli	a2,a2,0x1
 4f8:	00a51513          	slli	a0,a0,0xa
 4fc:	00180813          	addi	a6,a6,1
 500:	01d76733          	or	a4,a4,t4
 504:	01c6e6b3          	or	a3,a3,t3
 508:	00666633          	or	a2,a2,t1
 50c:	0018d893          	srli	a7,a7,0x1
 510:	00f567b3          	or	a5,a0,a5
 514:	f505f6e3          	bgeu	a1,a6,460 <.L83>

00000518 <.L93>:
 518:	00000513          	li	a0,0

0000051c <.L114>:
 51c:	00c12403          	lw	s0,12(sp)
 520:	01010113          	addi	sp,sp,16
 524:	00008067          	ret

00000528 <.L113>:
 528:	fa0516e3          	bnez	a0,4d4 <.L104>
 52c:	00000513          	li	a0,0
 530:	fedff06f          	j	51c <.L114>

00000534 <.L110>:
 534:	000007b7          	lui	a5,0x0
 538:	00078793          	mv	a5,a5
 53c:	00000813          	li	a6,0
 540:	f0dff06f          	j	44c <.L69>

00000544 <VCTrieGetNodeCount>:
 544:	000007b7          	lui	a5,0x0
 548:	0207a503          	lw	a0,32(a5) # 20 <VCTrieInsert+0x20>
 54c:	00008067          	ret

00000550 <VCTrieGetExcessiveCount>:
 550:	000007b7          	lui	a5,0x0
 554:	0647a503          	lw	a0,100(a5) # 64 <.L46>
 558:	00008067          	ret

0000055c <VCEntryIsValid>:
 55c:	00052703          	lw	a4,0(a0)
 560:	01e00793          	li	a5,30
 564:	00e7e863          	bltu	a5,a4,574 <.L119>
 568:	00852503          	lw	a0,8(a0)
 56c:	01f53513          	sltiu	a0,a0,31
 570:	00008067          	ret

00000574 <.L119>:
 574:	00000513          	li	a0,0
 578:	00008067          	ret

0000057c <VCEntryIsInvalid>:
 57c:	00052703          	lw	a4,0(a0)
 580:	01e00793          	li	a5,30
 584:	00e7ea63          	bltu	a5,a4,598 <.L122>
 588:	00852503          	lw	a0,8(a0)
 58c:	01f53513          	sltiu	a0,a0,31
 590:	00154513          	xori	a0,a0,1
 594:	00008067          	ret

00000598 <.L122>:
 598:	00100513          	li	a0,1
 59c:	00008067          	ret

000005a0 <VCEntryInvalidate>:
 5a0:	01f00793          	li	a5,31
 5a4:	00f52023          	sw	a5,0(a0)
 5a8:	00f52423          	sw	a5,8(a0)
 5ac:	00008067          	ret

Disassembly of section .text.startup:

00000000 <_GLOBAL__sub_I_trie>:
   0:	000007b7          	lui	a5,0x0
   4:	00078793          	mv	a5,a5
   8:	01f00713          	li	a4,31
   c:	0007a023          	sw	zero,0(a5) # 0 <_GLOBAL__sub_I_trie>
  10:	0007a223          	sw	zero,4(a5)
  14:	00e7a823          	sw	a4,16(a5)
  18:	0007aa23          	sw	zero,20(a5)
  1c:	00e7ac23          	sw	a4,24(a5)
  20:	0207a023          	sw	zero,32(a5)
  24:	0607a223          	sw	zero,100(a5)
  28:	00008067          	ret
