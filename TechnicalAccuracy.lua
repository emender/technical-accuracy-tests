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
    -- Load all required libraries.
    dofile(getScriptDirectory() .. "lib/xml.lua")
    dofile(getScriptDirectory() .. "lib/publican.lua")

    -- Create publican object.
    if path.file_exists("publican.cfg") then
        TechnicalAccuracy.publicanInstance = publican.create("publican.cfg")

        -- Create xml object.
        TechnicalAccuracy.xmlInstance = xml.create(TechnicalAccuracy.publicanInstance:findMainFile())

        -- Print information about searching links.
        warn("Searching for links in the book ...")
        TechnicalAccuracy.allLinks = TechnicalAccuracy.findLinks()
    else
        fail("publican.cfg does not exist")
    end

    if TechnicalAccuracy.forbiddenLinks then
        warn("Found forbiddenLinks CLI option: " .. TechnicalAccuracy.forbiddenLinks)
        local links = TechnicalAccuracy.forbiddenLinks:split(",")
        for _,link in ipairs(links) do
            warn("Adding following link into black list: " .. link)
            -- insert into table
            TechnicalAccuracy.forbiddenLinksTable[link] = link
        end
    end
end



--
--- Parse links from the document.
--
--  @return table with links
function TechnicalAccuracy.findLinks()
    local links  = TechnicalAccuracy.xmlInstance:getAttributesOfElement("href", "link")
    local ulinks = TechnicalAccuracy.xmlInstance:getAttributesOfElement("url",  "ulink")
    if links then
        warn("link:  " .. #links)
    else
        warn("no link tag found")
    end
    if ulinks then
        warn("ulink: " .. #ulinks)
    else
        warn("no ulink tag found")
    end
    if links then
        if ulinks then
            -- interesing, both link and ulink has been found, DB4+DB5 mix?
            return table.appendTables(links, ulinks)
        else
            return links
        end
    else
        return ulinks
    end
end



--
--- Convert table with links to the string where links are separated by new line.
--  This format is used because bash function accepts this format.
--
--  @return string which contains all links separated by new line.
function TechnicalAccuracy.convertListForMultiprocess()
    local convertedLinks = ""

    -- Go through all links and concatenate them. Put each link into double quotes
    -- because of semicolons in links which ends bash command.
    for _, link in pairs(TechnicalAccuracy.allLinks) do
        -- Skip every empty line.
        if not link:match("^$") then
            convertedLinks = convertedLinks .. "\"" .. link .. "\"\n"
        end
    end

    -- Remove last line break.
    return convertedLinks:gsub("%s$", "")
end



--
--- Runs command which tries all links and then parse output of this command.
--  In the ouput table is information about each link in this format: link______exitCode.
--  link is link, exitCode is exit code of curl command, it determines which error occured.
--  These two information are separated by six underscores.
--
--  @param links string with links separated by new line
--  @return list with link and exit code
function TechnicalAccuracy.tryLinks(links)
    local list = {}

    local output = execCaptureOutputAsTable(TechnicalAccuracy.composeCommand(links))

    for _, line in ipairs(output) do
        --local link, exitCode = line:match("(.+)______(%d+)$")
        --list[link] = exitCode

        -- line should consist of three parts separated by spaces:
        -- 1) original URL (as written in document)
        -- 2) HTTP code (200, 404 etc.)
        -- 3) final URL (it could differ from the original URL if request redirection has been performed)
        local originalUrl, httpCode, effectiveUrl = line:match("(%g+) (%d+) (.+)$")
        local result = {}
        result.originalUrl = originalUrl
        result.effectiveUrl = effectiveUrl
        result.httpCode = httpCode
        list[effectiveUrl] = result
    end

    return list
end



---
--- Reports non-functional or blacklisted external links.
---
function TechnicalAccuracy.testExternalLinks()
    if table.isEmpty(TechnicalAccuracy.allLinks) then
        pass("No links found.")
        return
    end
    pass("OK")
end

