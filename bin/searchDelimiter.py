#!/usr/bin/python

import sys

# Usage example :
# $ python searchDelimiter.py "xx;xxx,xx;xxxx;xxx,xx" "yyyy,yyyy;yy;yy,yy"

# --------------------------------------------------------------------------------
# Searchs in the two strings the delimiter with the highest and the same frequency
# --------------------------------------------------------------------------------
def searchDelimiterWithHighestAndSameFrequency(string1, string2):
	delimiter = "NO_DELIMITER"
	knownDelimiters = [",", "\t", ";", "|", " "];
	n0 = 1
	for d in knownDelimiters:
		n1 = len(string1.split(d))
		n2 = len(string2.split(d))
		if ((n1 == n2) & (n1 > n0)):
			delimiter = d
			n0 = n1
	return delimiter;
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Transforms the content of substrings surrounded by quotes 
# --------------------------------------------------------------------------------
def transformSubstringsSurroundedByQuotes(aString, aChar):
	outputString = ""
	joker = "Z"
	writeJoker = False
	if (aString[0] == aChar):
		writeJoker = True
	for s in aString:
		if (writeJoker == False) & (s == aChar):
			writeJoker = True
		elif (writeJoker == True) & (s == aChar):
			writeJoker = False
			s = joker
		if (writeJoker == True):
			outputString += joker
		else:
			outputString += s
	return outputString;
# --------------------------------------------------------------------------------

string1 = sys.argv[1]
string2 = sys.argv[2]

string1 = transformSubstringsSurroundedByQuotes(string1, "\"")
string2 = transformSubstringsSurroundedByQuotes(string2, "\"")

string1 = transformSubstringsSurroundedByQuotes(string1, "'")
string2 = transformSubstringsSurroundedByQuotes(string2, "'")

delimiter = searchDelimiterWithHighestAndSameFrequency(string1, string2)
if delimiter == "\t":
	delimiter = "\\t"

print delimiter

