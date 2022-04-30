import httpclient, json, os, strutils, parsecfg

let cfg = loadConfig("config.ini")
let apiUrl = cfg.getSectionValue("farsireader", "apiUrl")
let apiKey = cfg.getSectionValue("farsireader", "apiKey")
let ttsFormat = cfg.getSectionValue("farsireader", "ttsFormat")
let ttsSpeaker = cfg.getSectionValue("farsireader", "ttsSpeaker")

proc usage*() = 
  let progName = paramStr(0)
  let usageMsg = """usage: $1 command source_text output_audio

Commands:
    tts    -- Generate Text-To-Speech audio file
    sub    -- Generate subliminal audio file
"""
  quit(usageMsg % [progName])

proc getFileExt(filePath: string): string =
  let extSplit = filePath.split('.')
  result = extSplit[extSplit.high]

proc genTTS*(textInput, audioOutput: string) =
  if getFileExt(audioOutput) != ttsFormat:
    quit("output_audio extension should be .$1" % [ttsFormat])
  var ttsJson = %* 
    {
      "Text": readFile(textInput),
      "Speaker": ttsSpeaker,
      "PitchLevel": "0",
      "PunctuationLevel": "0",
      "SpeechSpeedLevel": "0",
      "ToneLevel": "11",
      "GainLevel": "0",
      "BeginningSilence": "0",
      "EndingSilence": "1",
      "Format": ttsFormat,
      "Base64Encode": "0",
      "Quality": "normal",
      "APIKey": apiKey
    }
  let client = newHttpClient()
  client.headers = newHttpHeaders({ "Content-Type": "application/json" })
  let response = client.request(apiUrl, httpMethod = HttpPost, body = $ttsJson)
  writeFile(audioOutput, response.body)

proc genSub*(textInput, audioOutput: string) =
  let tmpFile =  textInput & '.' & ttsFormat
  genTTS(textInput, tmpFile)
  let ttsVolume = cfg.getSectionValue("subliminal", "ttsVolume")
  var cmd = "ffmpeg -stream_loop -1 -i $1 -fs 10M  -filter:a \"volume=$2\" long.ogg" % [tmpFile, ttsVolume]
  discard execShellCmd(cmd)
  let background = cfg.getSectionValue("subliminal", "background")
  cmd = "ffmpeg -i $1 -i long.ogg -filter_complex \"[1:a]adelay=11111,amix=inputs=2:duration=shortest\" -metadata title=$2 -b:a 320k $2" %
  [background, audioOutput]
  discard execShellCmd(cmd)
  removeFile("long.ogg")
  removeFile(tmpFile)
