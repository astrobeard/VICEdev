# cython: language_level = 3, boundscheck = False 

from __future__ import absolute_import 
__all__ = [
	"test_fromfile_constructor", 
	"test_fromfile_destructor" 
] 
from .._test_utils import unittest 
from . cimport _fromfile 


def test_fromfile_constructor(): 
	""" 
	Tests the fromfile constructor function at vice/src/objects/fromfile.h 
	""" 
	return unittest("Fromfile constructor", _fromfile.test_fromfile_initialize) 


def test_fromfile_destructor(): 
	""" 
	Tests the fromfile destructor function at vice/src/objects/fromfile.h 
	""" 
	return unittest("Fromfile destructor", _fromfile.test_fromfile_free) 
