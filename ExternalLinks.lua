-- ExternalLinks.lua

-- Emender test to verify that all external links are functional
-- Copyright (C) 2014-2017 Jaromir Hradilek, Pavel Vomacka

-- This program is free software:  you can redistribute it and/or modify it
-- under the terms of  the  GNU General Public License  as published by the
-- Free Software Foundation, version 3 of the License.
--
-- This program  is  distributed  in the hope  that it will be useful,  but
-- WITHOUT  ANY WARRANTY;  without  even the implied warranty of MERCHANTA-
-- BILITY or  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
-- License for more details.
--
-- You should have received a copy of the GNU General Public License  along
-- with this program. If not, see <http://www.gnu.org/licenses/>.

ExternalLinks = {
    metadata = {
        description = "Verify that all external links are functional.",
        authors = "Jaromir Hradilek, Pavel Vomacka, Pavel Tisnovsky",
        emails = "jhradilek@redhat.com, pvomacka@redhat.com, ptisnovs@redhat.com",
        changed = "2017-04-19",
        tags = {"DocBook", "Release"}
    },
}

--
--- Function which runs first. This is place where all objects are created.
--
function ExternalLinks.setUp()
end

--
--- Entry point to the test itself
--
function ExternalLinks.testExternalLinks()
    pass("OK")
end

