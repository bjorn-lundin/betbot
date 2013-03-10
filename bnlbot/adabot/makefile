###############################################################################
#                                                                             #
#                                JSON_Test                                    #
#                                                                             #
#                                Make File                                    #
#                                                                             #
#                      Copyright (C) 2011, Thomas Løcke                       #
#                                                                             #
# JSON_Test is free software; you can redistribute it and/or modify it under  #
# terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2, or (at your option) any later version.        #
# JSON_Test is distributed in the hope that it will be useful, but WITHOUT    #
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or       #
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for    #
# more details. You should have received a copy of the GNU General Public     #
# License distributed with JSON_Test. If not, write to the Free Software      #
# Foundation, 51 Franklin Street, Fifth Floor, Boston, MA 02110 - 1301, USA.  #
#                                                                             #
###############################################################################

all:
	gnatmake -P json_test

debug:
	BUILDTYPE=Debug gnatmake -P json_test

clean:
	gnatclean -P json_test
	BUILDTYPE=Debug gnatclean -P json_test