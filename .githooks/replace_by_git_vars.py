#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright: (c) 2016, [Daniel Dye (https://gist.github.com/dandye/dfe0870a6a1151c89ed9)]
# Copyright: (c) 2021, [Jean Claveau (https://gist.github.com/jclaveau/af2271b9fdf05f7f1983f492af5592f8)]
# Copyright: (c) 2023, [Raell Dottin (https://github.com/raelldottin)]
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

import sys
import os
import re
import subprocess

VERBOSE = 0
INPUTFILE = ""
OUTPUTFILE = ""
GITVARS = {}

# """
# Raell Dottin didn't use any of the bullshit below
# This script replaces vars written between brackets like "{{ remote.origin.url }}" by their values.
# Used as a pre-commit hook[2] to update the README.md file's and have badges matching the current branch
#
# [1] http://stackoverflow.com/questions/18673694/referencing-current-branch-in-github-readme-md
# [2] http://www.git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
# [4] https://gist.github.com/dandye/dfe0870a6a1151c89ed9
# """

def printVERBOSE(message: str):
    '''Print message if VERBOSE flag is enabled.'''
    if VERBOSE:
        print(message)

def getGitVars():
    '''Get all the git variables from INPUTFILE''' 
    printVERBOSE(f"Scanning {INPUTFILE} for git variables.")

    with open(INPUTFILE, 'r') as template_file:
        for line in template_file.readlines():
            printVERBOSE(f"Processing {line}")
            pattern = r'{+\s[a-z]+\.[a-z]+\s}+'
            matches = re.findall(pattern, line, re.DOTALL)
            for match in matches:
                pattern = r'{+\s([a-z]+\.[a-z]+)\s}}'
                results = re.search(pattern, match)
                result = results.group(1)
                printVERBOSE(f"{results.group(1)=}")
                if result in GITVARS.keys():
                    pass
                else:
                    GITVARS[result] = ''

def setGiVars():
    '''Set the values for the GITVARS dictionary'''
    GITVARS["remote.origin.url"] = (subprocess.check_output(['git', 'config', '--get', 'remote.origin.url']).strip().decode("utf-8"))
    GITVARS["repository.name"] = re.findall("([^:]+)\.git$", GITVARS["remote.origin.url"])[0]
    GITVARS["current.branch"] = (subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD", ]).strip().decode("utf-8"))
    GITVARS["current.commit"] = (subprocess.check_output([ "git", "rev-parse", "HEAD", ]).strip().decode("utf-8"))
    GITVARS["tags"] = (subprocess.check_output(["git", "tag", "--list",]).strip().decode("utf-8"))

    for key in GITVARS.keys():
        if not GITVARS[key]:
            GITVARS[key] = (subprocess.check_output(['git', 'config', key,]).strip().decode("utf-8"))

def writeOUTPUTFILE():
    '''Write the output file with the replaced keywords'''
    lines = open(INPUTFILE).readlines()
    changed = False
    with open(OUTPUTFILE, "w") as fh:
        fh.write("<!---\n")
        fh.write(
            "This file is auto-generate by a github hook please modify "
            + INPUTFILE
            + " if you don't want to loose your work\n"
        )
        fh.write("-->\n")
        for line in lines:
            new_line = line
            for entry in GITVARS:
                pattern = r'{+\s'+ entry + r'\s}+'
                if len(re.findall(pattern, new_line)):
                    printVERBOSE(f"PRE: {pattern=} {entry=} {GITVARS[entry]=} {new_line=}")
                    new_line = re.sub(pattern, GITVARS[entry], new_line)
                    printVERBOSE(f"POST: {pattern=} {entry=} {GITVARS[entry]=} {new_line=}")
                    printVERBOSE("Found {{ " + entry + " }} in:\n   " + line + "=> " + new_line)
                    changed = True
        
            fh.write(new_line)

    if not changed and VERBOSE:
        print("No variable found in " + OUTPUTFILE)

    subprocess.check_output(["git", "add", OUTPUTFILE])

    # If OUTPUTFILE and INPUTFILE are the same only the replacement will be added for commit
    with open(INPUTFILE, "w") as fh:
        for line in lines:
            fh.write(line)

    printVERBOSE(OUTPUTFILE + " variables replaced")

def help():
    '''Display help message'''
    print(f"{os.path.basename(__file__)} [INPUTFILE] [ouput_file] [-v]")

def processArgs(argv: list):
    '''Process command line arguments'''
    global INPUTFILE
    global OUTPUTFILE
    global VERBOSE

    printVERBOSE("Processing command line arguments.")

    INPUTFILE = argv[1]
    OUTPUTFILE = argv[2]
    VERBOSE = len(argv) == 4 and argv[3] == "-v"

def main():
    '''Main function'''
    global INPUTFILE
    argv = sys.argv
    if len(argv) < 3:
        help()
        quit()
    else:
        processArgs(argv)
        getGitVars()
        setGiVars()
        writeOUTPUTFILE()

if __name__ == '__main__':
    main()
