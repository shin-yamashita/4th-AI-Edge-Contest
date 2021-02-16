#!/usr/bin/env python3

import numpy as np

sfile = "srmon.mot"

buf = np.zeros(32768, dtype=np.int)

with open(sfile, 'r') as f:
  recs = f.readlines()


ladr = 0

for rec in recs:
  rec = rec.strip()
  sr = rec[0:2]
  if sr == 'S3' :
    nb = int(rec[2:4], 16) - 5
    addr = int(rec[5:12], 16)
#    print("nb:%d addr:%x"%(nb,addr))
    for i in range(nb):
      buf[addr+i] = int(rec[12+i*2:12+i*2+2], 16)
#      print("%02x"%int(rec[i:i+2], 16))
      ladr = max(ladr, addr+i)
  else:
    print(rec)

for i in range(ladr+4):
  if i % 16 == 0: print("\n%04x : "%i, end='')
  print("%02x "%buf[i], end='')

