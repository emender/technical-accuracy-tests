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
    forbiddenLinksPatterns = {},
    forbiddenLinksTable = {},
    customerPortalLinks = {},
    exampleList = {"example%.com", "example%.edu", "example%.net", "example%.org",
                 "localhost", "127%.0%.0%.1", "::1"},
    internalList = {},
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

    -- Create table containing all forbidden links
    if TechnicalAccuracy.forbiddenLinks then
        yap("Found forbiddenLinks CLI option: " .. TechnicalAccuracy.forbiddenLinks)
        local links = TechnicalAccuracy.forbiddenLinks:split(",")
        for _,link in ipairs(links) do
            yap("Adding following link into black list: " .. link)
            -- insert into table
            TechnicalAccuracy.forbiddenLinksPatterns[link] = link
        end
    end

    -- Create publican object.
    if path.file_exists("publican.cfg") then
        TechnicalAccuracy.publicanInstance = publican.create("publican.cfg")

        -- Create xml object.
        TechnicalAccuracy.xmlInstance = xml.create(TechnicalAccuracy.publicanInstance:findMainFile())

        -- Print information about searching links.
        yap("Searching for links in the book ...")
        TechnicalAccuracy.allLinks, TechnicalAccuracy.forbiddenLinksTable, TechnicalAccuracy.customerPortalLinks = TechnicalAccuracy:findLinks()
    else
        fail("publican.cfg does not exist")
    end
end



--
-- Check if the given link is part of forbidden site.
--
function TechnicalAccuracy:isForbiddenLink(link)
    for _,forbiddenLink in pairs(self.forbiddenLinksPatterns) do
        if string.find(link, forbiddenLink, 1, true) then
            return true
        end
    end
    return false
end



--
-- Check if the given link links to the customer portal.
--
function TechnicalAccuracy:isCustomerPortalLink(link)
    return link:startsWith("http://access.redhat.com") or
           link:startsWith("https://access.redhat.com") or
           link:startsWith("http://access.qa.redhat.com/") or
           link:startsWith("https://access.qa.redhat.com/")
end



--
-- Add all regular not-forbidden links from the 'links' table to the 'allLinks' table.
-- Forbidden links are inserted into the 'forbiddenLinks' table.
--
function TechnicalAccuracy:addLinks(allLinks, forbiddenLinks, customerPortalLinks, links)
    if links then
        for _, link in ipairs(links) do
            if self:isForbiddenLink(link) then
                -- verbose mode
                -- warn("removing " .. link)
                table.insert(forbiddenLinks, link)
            elseif self:isCustomerPortalLink(link) then
                -- verbose mode
                -- warn("customer portal link " .. link)
                table.insert(customerPortalLinks, link)
            else
                -- verbose mode
                -- warn("adding " .. link)
                table.insert(allLinks, link)
            end
        end
    end
end



--
--- Parse links from the document.
--
--  @return table with links
function TechnicalAccuracy:findLinks()
    local links  = self.xmlInstance:getAttributesOfElement("href", "link")
    local ulinks = self.xmlInstance:getAttributesOfElement("url",  "ulink")
    if links then
        if #links == 1 then
            yap("found one <link> tag")
        else
            yap("found " .. #links .. " <link> tags")
        end
    else
        yap("no <link> tag found")
    end
    if ulinks then
        if #ulinks == 1 then
            yap("found one <ulink> tag")
        else
            yap("found " .. #ulinks .. " <ulink> tags")
        end
    else
        yap("no <ulink> tag found")
    end

    -- add all regular not-forbidden links from the 'links' table to the 'allLinks' table.
    local allLinks = {}
    local forbiddenLinks = {}
    local customerPortalLinks = {}
    self:addLinks(allLinks, forbiddenLinks, customerPortalLinks, links)
    self:addLinks(allLinks, forbiddenLinks, customerPortalLinks, ulinks)
    return allLinks, forbiddenLinks, customerPortalLinks
end



--
--- Convert table with links to the string where links are separated by new line.
--  This format is used because bash function accepts this format.
--
--  @return string which contains all links separated by new line.
function TechnicalAccuracy:convertListForMultiprocess()
    local convertedLinks = ""

    -- Go through all links and concatenate them. Put each link into double quotes
    -- because of semicolons in links which ends bash command.
    for _, link in pairs(self.allLinks) do
        -- Skip every empty line.
        if not link:match("^$") then
            convertedLinks = convertedLinks .. "\"" .. link .. "\"\n"
        end
    end

    -- Remove last line break.
    return convertedLinks:gsub("%s$", "")
end



--
--- Compose command in bash which tries all links using more processes.
--
--  @param links string with all links separated by new line.
--  @return composed command in string
function TechnicalAccuracy.composeCommand(links)

    local command =  [[ checkLink() {
    URL=$1

    echo -n "$1 "
    curl -4Ls --insecure --post302 --connect-timeout 5 --retry 5 --retry-delay 3 --max-time 20 -A 'Mozilla/5.0 (X11; Linux x86_64; rv:31.0) Gecko/20100101 Firefox/31.0' -w "%{http_code} %{url_effective}" -o /dev/null $1 | tail -n 1
    }

    export -f checkLink
    echo -e ']] .. links .. [[' | xargs -d'\n' -n1 -P0 -I url bash -c 'echo `checkLink url`' ]]
    -- This command checks whether link contains access.redhat.com/documentation. If it's true then replace this part
    -- by documentation-devel.engineering.redhat.com/site/documentation . Then calls curl. Curl with these parameters can run parallelly (as many processes as OS allows).
    -- Maximum time for each link is 5 seconds. Output of function checkLink is:
    --                                                        tested_url______exit_code

    return command
end



--
--- Runs command which tries all links and then parse output of this command.
--  In the ouput table is information about each link in this format: link______exitCode.
--  link is link, exitCode is exit code of curl command, it determines which error occured.
--  These two information are separated by six underscores.
--
--  @param links string with links separated by new line
--  @return list with link and exit code
function TechnicalAccuracy:tryLinks(links)
    local list = {}

    local output = execCaptureOutputAsTable(self.composeCommand(links))

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



--
--- Function that find all links to anchors.
--
--  @param link
--  @return true if link is link to anchor, otherwise false.
function TechnicalAccuracy.isAnchor(link)
    -- If link has '#' at the beginning or if the link doesnt starts with protocol and contain '#' character
    -- then it is link to anchor.
    if link:match("^#") or (not link:match("^%w%w%w%w?%w?%w?://") and link:match("#")) then
        return true
    end

    return false
end



--
--- Checks whether link has prefix which says that this is mail or file, etc.
--
--  @param link
--  @return true if link is with prefix or false.
function TechnicalAccuracy.mailOrFileLink(link)
    if link:match("^mailto:") or link:match("^file:") or link:match("^ghelp:")
        or link:match("^install:") or link:match("^man:") or link:match("^help:") then
        return true
    else
        return false
    end
end



--
--- Checks whether the link corresponds with one of patterns in given list.
--
--  @param link
--  @param list
--  @return true if pattern in list match link, false otherwise.
function TechnicalAccuracy.isLinkFromList(link, list)
    -- Go through all patterns in list.
    for i, pattern in ipairs(list) do
        if link:match(pattern) then
            -- It is example or internal link.
            return true
        end
    end
    return false
end



--
-- Replaces the ftp:// protocol specification by http://
--
function ftp2httpUrl(link)
    if link:startsWith("ftp://") then
        return link:gsub("^ftp://", "http://")
    else
        return link
    end
end



--
-- Check if one selected link is accessible.
--
function tryOneLink(linkToCheck)
    local command = TechnicalAccuracy.curlCommand .. TechnicalAccuracy.curlDisplayHttpStatusAndEffectiveURL .. linkToCheck .. " | tail -n 1"
    local output = execCaptureOutputAsTable(command)
    -- this function returns truth value only if:
    -- output must be generated, it should contain just one line
    -- and on the beginning of this line is HTTP status code 200 OK
    return output and #output==1 and string.startsWith(output[1], TechnicalAccuracy.HTTP_OK_CODE)
end



--
-- Checks all forbidden links.
--
function TechnicalAccuracy:checkForbiddenLinks()
    for _, link in pairs(self.forbiddenLinksTable) do
        fail("is blacklisted. See the emender.ini file in the guide repository for blacklisted links.", link)
    end
    if #self.forbiddenLinksTable > 0 then
        self.failure = true
    end
end



--
-- Checks all links pointing to the Customer Portal.
--
function TechnicalAccuracy:checkCustomerPortalLinks()
    for _, linkToCheck in ipairs(self.customerPortalLinks) do
        yap("Checking " .. linkToCheck)
        local command = self.curlCommand .. linkToCheck .. " | sed -n 's/<title>\\(.*\\)<\\/title>/\\1/p'"
        local output = execCaptureOutputAsTable(command)
        if not output or #output == 0 then
            fail("does not work.", linkToCheck)
            failure = true
        else
            local title = output[1]
            if not title then
                fail("page does not contain title", linkToCheck)
            else
                if title:trim():startsWith("Product Documentation") then
                    fail("gets redirected to the product documentation landing page.", linkToCheck)
                    failure = true
                else
                    yap("ok")
                end
            end
        end
    end
end



--
-- Checks all regular links.
--
function TechnicalAccuracy:checkRegularLinks()
    -- Convert list of links into string and then check all links using curl.
    local checkedLinks = self:tryLinks(self:convertListForMultiprocess())

    -- Go through all links and print the results out.
    for linkValue, result in pairs(checkedLinks) do
        local exitCode     = result.httpCode
        local originalUrl  = result.originalUrl
        local effectiveUrl = result.effectiveUrl
        if self.isAnchor(linkValue) then
            warn(linkValue .. " - Anchor")
        elseif self.mailOrFileLink(linkValue) then
            -- Mail or file link - warn
            warn(linkValue)
        elseif self.isLinkFromList(linkValue, self.exampleList) then
            -- Example or localhost - OK
            warn(linkValue .. " - Example")
        elseif self.isLinkFromList(linkValue, self.internalList) then
            -- Internal link - FAIL
            fail("internal link", linkValue)
            failure = true
        else
            -- Check exit code of curl command.
            if exitCode == self.HTTP_OK_CODE or exitCode == self.FTP_OK_CODE then
                -- special case for FTP, please see CCS-1278
                if linkValue:startsWith("ftp://") then
                    local htmlLink = ftp2httpUrl(linkValue)
                    if tryOneLink(htmlLink) then
                        -- ftp link is ok AND http link is ok as well
                        -- -> display suggestion to writer that he/she should use http:// instead of ftp://
                        fail("used the FTP protocol.", linkValue)
                        link("Use the HTTP protocol instead of FTP, suggested link: ", htmlLink, htmlLink)
                        failure = true
                    else
                        -- only ftp:// link is accessible
                        --pass(linkValue)
                    end
                else
                    --pass(linkValue)
                end
            elseif exitCode == self.FORBIDDEN then
                warn("403 Forbidden")
                if linkValue then
                    link("Forbidden link " .. linkValue, linkValue)
                else
                    link("Forbidden", "link not set (strange)")
                end
            else
                -- the URL is not accessible -> the test should fail
                fail("does not work.", originalUrl)

                -- if the request has been redirected to another URL, show the original URL and redirected one
                ------ this code works, but is not required by users(?)
                ------ if originalUrl ~= effectiveUrl then
                ------     fail("gets redirected to the product documentation landing page", originalUrl)
                ------     failure = true
                ------     link("URL in document: " .. originalUrl, originalUrl)
                ------     link("Redirected URL: " .. effectiveUrl, effectiveUrl)
                ------ else
                ------ -- no redirection -> show the original URL as is written in the document
                ------     link("URL to check: " .. originalUrl, originalUrl)
                ------ end
            end
        end
    end
end



--
-- Print test results in case of zero failures.
--
function TechnicalAccuracy:printOverallResults()
    if not self.failure then
        local found = #self.allLinks + #self.customerPortalLinks
        pass("Congratulations! All external links (found " .. found .. ") work.")
    end
end



---
--- Reports non-functional or blacklisted external links.
---
function TechnicalAccuracy.testExternalLinks()
    TechnicalAccuracy.failure = nil

    TechnicalAccuracy:checkForbiddenLinks()
    TechnicalAccuracy:checkCustomerPortalLinks()
    TechnicalAccuracy:checkRegularLinks()
    TechnicalAccuracy:printOverallResults()
end

