#!/usr/bin/env python3

import io
import uuid


def createflowfile ( attributes, content ):
  numattrs = len(attributes)

  if numattrs <= 65535:
    numattrbytes = (numattrs).to_bytes(2, byteorder='big')
  else:
    numattrbytes = (numattrs).to_bytes(6, byteorder='big')

  attrarray = bytearray()

  for key, val in attrs.items():
    if len(key) <= 65535:
      attrarray.extend((len(key)).to_bytes(2, byteorder='big'))
    else:
      attrarray.extend((len(key)).to_bytes(6, byteorder='big'))
    attrarray.extend(key.encode('utf-8'))
    if len(val) <= 65535:
      attrarray.extend((len(val)).to_bytes(2, byteorder='big'))
    else:
      attrarray.extend((len(val)).to_bytes(6, byteorder='big'))
    attrarray.extend(val.encode('utf-8'))

  contentlen = (len(content)).to_bytes(8, byteorder='big')

  ffobject = io.BytesIO(b'NiFiFF3' + numattrbytes + attrarray + contentlen + content.encode('utf-8'))

  return ffobject;
  


if __name__ == '__main__':
  filename = 'poop.txt'
  content = 'Hello... this is content'

  attrs = dict()

  attrs['filename'] = filename
  attrs['nf.file.name'] = filename
  attrs['nf.file.path'] = './'
  attrs['path'] = './'
  attrs['uuid'] = str(uuid.uuid4())

  flowfile = open('./' + filename, 'wb')
  flowfile.write(createflowfile(attrs, content).read())
