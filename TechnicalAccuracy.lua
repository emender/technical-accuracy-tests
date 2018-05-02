--[[
The Technical Accuracy test verifies that documentation is technically 
accurate. For example, it reports non-functional or blacklisted external links.

Copyright (C) 2014-2018 Jaromir Hradilek, Pavel Vomacka, Pavel Tisnovsky, Lana 
Ovcharenko

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.
]]

TechnicalAccuracy = {
    metadata = {
        description = "The Techical Accuracy test verifies that documentation is technically accurate. For example, it reports non-functional or blacklisted external links.",
        authors = "Jaromir Hradilek, Pavel Vomacka, Pavel Tisnovsky, Lana Ovcharenko",
        emails = "jhradilek@redhat.com, pvomacka@redhat.com, ptisnovs@redhat.com, lovchare@redhat.com",
        changed = "2018-04-27",
        tags = {"DocBook", "Release"}
    },
    requires = {"wget", "curl"},
    xmlObj = nil,
    regularLinks = {},
    language = "en-US",
    blacklistedLinks = nil,
    blacklistedLinkPatterns = {},
    blacklistedLinksTable = {},
    customerPortalLinks = {},
    exampleList = {"example%.com", "example%.edu", "example%.net", "example%.org", "localhost", "127%.0%.0%.1", "::1"},
    internalList = {},
    HTTP_OK_CODE = "200",
    FTP_OK_CODE = "226",
    ERROR_CODE = "404",
    FORBIDDEN_CODE = "403",
    --
    brokenCustomerPortalLinkCount = 0,
    forbiddenCustomerPortalLinkCount = 0,
    untitledCustomerPortalLinkCount = 0,
    redirectedCustomerPortalLinkCount = 0,
    okCustomerPortalLinkCount = 0,
    --
    ftpValidRegularLinkCount = 0,
    ftpInvalidRegularLinkCount = 0,
    brokenRegularLinkCount = 0,
    forbiddenRegularLinkCount = 0,
    internalRegularLinkCount = 0,
    anchorRegularLinkCount = 0,
    exampleRegularLinkCount = 0,
    commandRegularLinkCount = 0,
    okRegularLinkCount = 0
}



-- Entry point for the test.
function TechnicalAccuracy.setUp()
    TechnicalAccuracy.isReady = TechnicalAccuracy:checkVariables()
    if not TechnicalAccuracy.isReady then
        return
    end
    TechnicalAccuracy:findLinks()
    
    -- Forbidden links passed as command line arguments.
    if TechnicalAccuracy.blacklistedLinks then
        local links = TechnicalAccuracy.blacklistedLinks:split(",")
        for _,link in ipairs(links) do
            table.insert(TechnicalAccuracy.blacklistedLinkPatterns, link)
        end
        if #TechnicalAccuracy.blacklistedLinkPatterns > 1 then
            pass("Processed " .. #TechnicalAccuracy.blacklistedLinkPatterns .. " blacklisted links from user input.")
        elseif #TechnicalAccuracy.blacklistedLinkPatterns == 1 then
            pass("Processed 1 blacklisted link from user input.")
        end
    end
end



function TechnicalAccuracy:checkVariables()
    local publicanLib = getScriptDirectory() .. "lib/publican.lua"
    local xmlLib = getScriptDirectory() .. "lib/xml.lua"
    if not canOpenFile(publicanLib) or
            not canOpenFile(xmlLib) then
        return false
    end
    dofile(publicanLib)
    dofile(xmlLib)
    local publicanFile = "publican.cfg"
    if not canOpenFile(publicanFile) then
        return false
    end
    local pubObj = publican.create("publican.cfg")
    local masterFile = pubObj:findMainFile()
    if not canOpenFile(masterFile) then
        return false
    end
    pass("Master file: " .. masterFile)
    self.xmlObj = xml.create(masterFile)
    return true
end



function canOpenFile(file)
    local input = io.open(file, "r")
    if input then
        input:close()
        return true
    end
    fail("Missing " .. file .. "...")
    return false
end



function TechnicalAccuracy:isBlacklistedLink(link)
    for _,pattern in pairs(self.blacklistedLinkPatterns) do
        if link:find(pattern, 1, true) then
            return true
        end
    end
    return false
end



function isCustomerPortalLink(link)
    return link:startsWith("http://access.redhat.com") or
            link:startsWith("https://access.redhat.com") or
            link:startsWith("http://access.qa.redhat.com") or
            link:startsWith("https://access.qa.redhat.com")
end



-- Sort links into groups.
function TechnicalAccuracy:sortLinks(links)
    if links then
        for _, link in ipairs(links) do
            if self:isBlacklistedLink(link) then
                table.insert(self.blacklistedLinksTable, link)
            elseif isCustomerPortalLink(link) then
                table.insert(self.customerPortalLinks, link)
            else
                table.insert(self.regularLinks, link)
            end
        end
    end
end



function TechnicalAccuracy:findLinks()
    local links = self.xmlObj:getAttributesOfElement("href", "link")
    local ulinks = self.xmlObj:getAttributesOfElement("url", "ulink")
    if links then
        pass("<link> tags found: " .. #links)
    else
        pass("No <link> tags found.")
    end
    if ulinks then
        pass("<ulink> tags found: " .. #ulinks)
    else
        pass("No <ulink> tags found.")
    end

    -- Sort links into groups.
    self:sortLinks(links)
    self:sortLinks(ulinks)
    pass("Blacklisted links: " .. #self.blacklistedLinksTable)
    pass("Customer Portal links: " .. #self.customerPortalLinks)
    pass("Regular links: " .. #self.regularLinks)
end



-- Check if the link has a "command" prefix such as "mailto:".
function TechnicalAccuracy.isCommandLink(link)
    if link:startsWith("mailto:") or 
            link:startsWith("file:") or 
            link:startsWith("ghelp:") or
            link:startsWith("install:") or 
            link:startsWith("man:") or 
            link:startsWith("help:") then
        return true
    end
    return false
end



-- Check if the link is in a pattern list.
function TechnicalAccuracy.isLinkFromList(link, patternList)
    for _, pattern in ipairs(patternList) do
        if link:match(pattern) then
            return true
        end
    end
    return false
end



function TechnicalAccuracy:checkBlacklistedLinks()
    if #self.blacklistedLinksTable > 0 then
        fail(string.upper("Analyzing blacklisted links... See emender.ini in the documentation repository."))
    end
    for _, link in pairs(self.blacklistedLinksTable) do
        fail(link)
    end
end



function getPageTitle(link)
    local response = execCaptureOutputAsString("wget --quiet -O - " .. link)
    if not response then
        return nil
    end
    local title = response:match("<title>.+</title>")
    if not title then
        return nil
    end
    return title:gsub("<title>", ""):gsub("</title>", "")
end



function curlCommand(link)
    return "curl --insecure -w '%{url_effective}\\n %{http_code}\\n' -I -L -s -S " .. link .. " -o /dev/null"
end



function TechnicalAccuracy:checkLinks(links, message)
    if #links > 0 then
        pass(string.upper(message))
    end
    local resultsTable = {}
    resultsTable["ftpValidLinkCount"] = 0
    resultsTable["ftpInvalidLinkCount"] = 0
    resultsTable["brokenLinkCount"] = 0
    resultsTable["forbiddenLinkCount"] = 0
    resultsTable["untitledLinkCount"] = 0
    resultsTable["redirectedLinkCount"] = 0
    resultsTable["internalLinkCount"] = 0
    resultsTable["exampleLinkCount"] = 0
    resultsTable["anchorLinkCount"] = 0
    resultsTable["commandLinkCount"] = 0
    resultsTable["okLinkCount"] = 0
    resultsTable["unknownLinkCount"] = 0
    for _, link in ipairs(links) do
        local pageTitle = getPageTitle(link)
        local redirectAndStatusCode = execCaptureOutputAsTable(curlCommand(link))
        if link:startsWith("ftp://") then
            local httpLink = link:gsub("^ftp://", "http://")
            if execCaptureOutputAsTable(curlCommand(httpLink))[2]:trim() == self.HTTP_OK_CODE then
                fail(link .. " uses FTP protocol, but you can replace it with HTTP and it will work.")
                resultsTable["ftpValidLinkCount"] = resultsTable["ftpValidLinkCount"] + 1
            else
                fail(link .. " uses FTP protocol, and replacing it with HTTP will not work.")
                resultsTable["ftpInvalidLinkCount"] = resultsTable["ftpInvalidLinkCount"] + 1
            end
        elseif redirectAndStatusCode[2]:trim() == self.ERROR_CODE then
            fail(link .. " is broken (" .. self.ERROR_CODE .. " status code).")
            resultsTable["brokenLinkCount"] = resultsTable["brokenLinkCount"] + 1
        elseif redirectAndStatusCode[2]:trim() == self.FORBIDDEN_CODE then
            fail(link .. " is forbidden (" .. self.FORBIDDEN_CODE .. " status code).")
            resultsTable["forbiddenLinkCount"] = resultsTable["forbiddenLinkCount"] + 1
        elseif redirectAndStatusCode[2]:trim() ~= self.HTTP_OK_CODE then
            fail(link .. " has " .. redirectAndStatusCode[2]:trim() .. " status code.")
            resultsTable["unknownLinkCount"] = resultsTable["unknownLinkCount"] + 1
        elseif not pageTitle or pageTitle == "" then
            fail(link .. " has no page title.")
            resultsTable["untitledLinkCount"] = resultsTable["untitledLinkCount"] + 1
        elseif redirectAndStatusCode[1] ~= cutOffLinkExtension(link):lower() and 
                not isAnchorLink(link) then
            fail(link .. " gets redirected.")
            resultsTable["redirectedLinkCount"] = resultsTable["redirectedLinkCount"] + 1
        elseif self.isLinkFromList(link:lower(), self.internalList) or 
                self.isLinkFromList(link, self.internalList) then
            warn(link .. " is internal.")
            resultsTable["internalLinkCount"] = resultsTable["internalLinkCount"] + 1
        elseif self.isLinkFromList(link:lower(), self.exampleList) or
                self.isLinkFromList(link, self.exampleList) then
            warn(link .. " is from example list.")
            resultsTable["exampleLinkCount"] = resultsTable["exampleLinkCount"] + 1
        elseif redirectAndStatusCode[1] ~= cutOffLinkExtension(link):lower() 
                and isAnchorLink(link) then
            warn(link .. " is an achor.")
            resultsTable["anchorLinkCount"] = resultsTable["anchorLinkCount"] + 1
        elseif self.isCommandLink(link) then
            warn(link .. " is a command.")
            resultsTable["commandLinkCount"] = resultsTable["commandLinkCount"] + 1
        else
            pass(link .. " is OK.")
            resultsTable["okLinkCount"] = resultsTable["okLinkCount"] + 1
        end
    end
    return resultsTable
end



function cutOffLinkExtension(link)
    if not link:find(".html", 1, true) then
        return link
    end
    return link:sub(1, link:find(".html", 1, true) - 1) .. link:sub(link:find(".html", 1, true) + 5)
end



function isAnchorLink(link, effectiveLink)
    if link:startsWith("#") then
        return true
    end
    local lastHash = link:lastIndexOf("#")
    local lastSlash = link:lastIndexOf("/")
    if lastHash and lastHash > lastSlash then
        return true
    end
    return false
end



function TechnicalAccuracy:printResults(resultsTable, name)
    pass(string.upper("Overall results for " .. name .. " links:"))
    fail("Valid FTP: " .. resultsTable["ftpValidLinkCount"])
    fail("Invalid FTP: " .. resultsTable["ftpInvalidLinkCount"])
    fail("Broken: " .. resultsTable["brokenLinkCount"])
    fail("Forbidden: " .. resultsTable["forbiddenLinkCount"])
    fail("Other status code: " .. resultsTable["unknownLinkCount"])
    fail("No page title: " .. resultsTable["untitledLinkCount"])
    fail("Redirected: " .. resultsTable["redirectedLinkCount"])
    warn("Internal: " .. resultsTable["internalLinkCount"])
    warn("From example list: " .. resultsTable["exampleLinkCount"])
    warn("Anchors: " .. resultsTable["anchorLinkCount"])
    warn("Commands: " .. resultsTable["commandLinkCount"])
    pass("OK: " .. resultsTable["okLinkCount"])
end



-- Test documentation for non-functional or blacklisted external links.
function TechnicalAccuracy.testExternalLinks()
    if not TechnicalAccuracy.isReady then
        return
    end
    TechnicalAccuracy:checkBlacklistedLinks()
    TechnicalAccuracy.customerPortalLinksResultsTable = TechnicalAccuracy:checkLinks(TechnicalAccuracy.customerPortalLinks, "Analyzing Customer Portal links...")
    TechnicalAccuracy.regularLinksResultsTable = TechnicalAccuracy:checkLinks(TechnicalAccuracy.regularLinks, "Analyzing regular links...")
    if #TechnicalAccuracy.customerPortalLinks > 0 then
        TechnicalAccuracy:printResults(TechnicalAccuracy.customerPortalLinksResultsTable, "Customer Portal")
    end
    if #TechnicalAccuracy.regularLinks > 0 then
        TechnicalAccuracy:printResults(TechnicalAccuracy.regularLinksResultsTable, "regular")
    end
end