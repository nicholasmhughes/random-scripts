#!/usr/bin/env python3


def readflowfile ( flowfile ):
  attrs = dict()

  header = flowfile.read(7) # NiFiFF3 header

  if header.decode('utf-8') != 'NiFiFF3':
    print('ERROR: FlowFile header not found!', file=sys.stderr)
    exit(1)

  bytes = flowfile.read(2) # Number of attrs
  numattrs = int.from_bytes(bytes, byteorder='big')

  if numattrs >= 65535:
    bytes = bytes + flowfile.read(4)
    numattrs = int.from_bytes(bytes, byteorder='big')

  currattr = 0

  while currattr < numattrs:
    bytes = flowfile.read(2) # Size of attribute name
    lenattrname = int.from_bytes(bytes, byteorder='big')
    if lenattrname >= 65535:
      bytes = bytes + flowfile.read(4)
      lenattrname = int.from_bytes(bytes, byteorder='big')
    attrname = flowfile.read(lenattrname)
    bytes = flowfile.read(2) # Size of attribute value
    lenattrval = int.from_bytes(bytes, byteorder='big')
    if lenattrval >= 65535:
      bytes = bytes + flowfile.read(4)
      lenattrval = int.from_bytes(bytes, byteorder='big')
    attrval = flowfile.read(lenattrval)
    attrs[attrname.decode('utf-8')] = attrval.decode('utf-8')
    currattr += 1

  bytes = flowfile.read(8) # Content size
  lencontent = int.from_bytes(bytes, byteorder='big')

  content = flowfile.read()

  if lencontent != len(content):
    print('ERROR: Content may be malformed!', file=sys.stderr)
    exit(1)

  return attrs, content;
  


if __name__ == '__main__':
  myfile = '/home/nhughes/dev/random-scripts/poop.txt'

  attrs, content = readflowfile(open(myfile, 'rb'))

  print(attrs['filename'])
  print(attrs)
  print(content)
