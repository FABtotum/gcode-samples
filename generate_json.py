#!/bin/env python
# -*- coding: utf-8; -*-
#
# (c) 2016 FABtotum, http://www.fabtotum.com
#
# This file is part of FABUI.
#
# FABUI is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# FABUI is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FABUI.  If not, see <http://www.gnu.org/licenses/>.

__authors__ = "Daniel Kesler"
__license__ = "GPL - https://opensource.org/licenses/GPL-3.0"
__version__ = "1.0"

# Import standard python module
import os
import sys
import json
import pprint
# Import external modules

# Import internal modules

ROOT=sys.argv[1]
OUTPUT='import.json'

def walkdir(rootdir):
    tree = {'objects' : {}, 'files' : {} }
    for root, subFolders, files in os.walk(rootdir):
        for folder in subFolders:
            #print 'Object [', folder, ']', os.path.join(root,folder)
            dirPath = os.path.join(root,folder)
            o = {
                'name' : folder,
                'path' : dirPath,
                'description' : '',
                'files' : {}
            }
            tree['objects'][dirPath] = o
            
        for fle in files:
            filePath = os.path.join(root,fle)
            
            obj = None
            #~ for o in tree['objects']:
            if root in tree['objects']:
                obj = tree['objects'][root]
            
            #print 'File [',fle,']',root
            f = {
                'name' : fle,
                'path' : filePath,
                'note' : ''
            }
            if obj is None:
                obj = tree
            obj['files'][filePath] = f
            
    return tree

tree = walkdir(ROOT)

# Attributes that should be preserved
obj_copy_attributes = ['description', 'name']
file_copy_attributes = ['name', 'note']

# Check if there already exists an import file
if os.path.exists(OUTPUT):
    json_f = open(OUTPUT)
    content = json.load(json_f)
    for op in tree['objects']:
        if op in content['objects']:
            obj_new = tree['objects'][op]
            obj = content['objects'][op]
            
            for attr in obj_copy_attributes:
                if attr in obj:
                    obj_new[attr] = obj[attr]
            
            for fp in obj_new['files']:
                
                if fp in obj['files']:
                    fimp = obj['files'][fp]
                    fnew = obj_new['files'][fp]
                    
                    for attr in file_copy_attributes:
                        if attr in fimp:
                            fnew[attr] = fimp[attr]

#~ print json.dumps(tree, sort_keys=True, indent=4 )

with open(OUTPUT, 'w') as outfile:
    json.dump(tree, outfile, sort_keys=True, indent=4)
