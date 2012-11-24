#!/bin/bash
ruby povraydemo-create-path-file.rb
povray -h750 -w750 juliaisle-withpath.pov
feh juliaisle-withpath.png &