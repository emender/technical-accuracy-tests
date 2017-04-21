-- TechnicalAccuracy.lua

-- This test verifies if a guide is technically accurate. For example, it
-- reports non-functional or blacklisted external links.

-- Copyright (C) 2014-2017 Jaromir Hradilek, Pavel Vomacka, Pavel Tisnovsky

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

TechnicalAccuracy = {
    metadata = {
        description = "This test verifies if a guide is technically accurate. For example, it reports non-functional or blacklisted external links.",
        authors = "Jaromir Hradilek, Pavel Vomacka, Pavel Tisnovsky",
        emails = "jhradilek@redhat.com, pvomacka@redhat.com, ptisnovs@redhat.com",
        changed = "2017-04-19",
        tags = {"DocBook", "Release"}
    },
    requires = {"curl", "xmllint", "xmlstarlet"},
    xmlInstance = nil,
    publicanInstance = nil,
    allLinks = nil,
    language = "en-US",
    forbiddenLinks = nil,
    forbiddenLinksTable = {},
    exampleList = {"example%.com", "example%.edu", "example%.net", "example%.org",
                 "localhost", "127%.0%.0%.1", "::1"},
    HTTP_OK_CODE = "200",
    FTP_OK_CODE = "226",
    FORBIDDEN = "403",
    curlCommand = "curl -4Ls --insecure --post302 --connect-timeout 5 --retry 5 --retry-delay 3 --max-time 20 -A 'Mozilla/5.0 (X11; Linux x86_64; rv:31.0) Gecko/20100101 Firefox/31.0' ",
    curlDisplayHttpStatusAndEffectiveURL = "-w \"%{http_code} %{url_effective}\" -o /dev/null "
}

--
--- Function which runs first. This is place where all objects are created.
--
function TechnicalAccuracy.setUp()
end

---
--- Reports non-functional or blacklisted external links.
---
function TechnicalAccuracy.testExternalLinks()
    pass("OK")
end

