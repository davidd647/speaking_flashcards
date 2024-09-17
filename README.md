# speaking_flashcards

# VocalCram (???)
# TalkToStudy
# SpeakToStudy

## to-do:

-fix the problem of having no audio-in/audio-out when coming back from other app
  -loss of permissions?
  -misordered delegation stack?
  -double-instantiation of synth/recog?
  -fails second instantiation of synth/recog?
  -double-firing of recog listen command? 
    -sometimes the recog seems to give a response, and then another response in 1 or 2 seconds...
  -should assignment of synth and recog classes be set in the global scope?
    -maybe this would help with reducing instances of double-assignment?
    -though not sure if this is even the root of the problem...