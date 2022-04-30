import os, procs 

if paramCount() != 3:
  usage()

let cmd = paramStr(1)
let textInput = paramStr(2)
let audioOutput = paramStr(3)

case cmd
of "tts": genTTS(textInput, audioOutput)
of "sub": genSub(textInput, audioOutput)
else: usage()
