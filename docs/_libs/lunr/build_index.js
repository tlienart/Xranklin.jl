// This file is adapted from the un-licensed repo
// https://github.com/BLE-LTER/Lunr-Index-and-Search-for-Static-Sites
// 
// ----------------------------------------------------------------------------
// 
// Index builder
// 
// Process (see main)
//      1. look for all html files to scrape in __site (see main, findHtml)
//      2. recover their path, title and body and make a dictionary with
//          that (see main, readHtml)
//      3. build a lunr index out of that (see build_index)
//      4. build a preview dictionary for each index page
//      5. write all this to a file that the lunr client can process
//
// What you may want to adjust
//      * in readHtml you may want to collect additional fields
//      * in buildIndex you may want to pass additional options to lunr
//          e.g. if you want boosting, stemming in another language, etc.
// 
// see also:
//  - https://lunrjs.com/guides/customising.html
//  - https://lunrjs.com/guides/language_support.html
// 
// ----------------------------------------------------------------------------
// 
// You may want to adjust the next few constants based on your use case
// 
//  TAGS_TO_SKIP: html tags + content that should be ignored for the index
//                for instance you may or may not want code to be indexed.
//                Note: script and style should stay there.
//  DIRS_TO_SKIP: list of folders of __site that shouldn't be checked for html
//                files to parse and index
//  OUTPUT_INDEX: where to place the resulting lunr index
// 
const TAGS_TO_SKIP = ["style", "script", "code", "fieldset"]
const DIRS_TO_SKIP = ["assets", "css", "libs"];
const OUTPUT_INDEX = "__site/libs/lunr/lunr_index.js";
// 
// ----------------------------------------------------------------------------

var path    = require("path");
var fs      = require("fs");
var lunr    = require("lunr");
var cheerio = require("cheerio");

// set by the builder to take the 'prepath' (url prefix) into account
var path_prefix = (process.argv.length < 3) ? ".." : process.argv[2]

// check if filename looks like html (.htm or .html)
function isHtml(filename) {
    lower = filename.toLowerCase();
    return (lower.endsWith(".htm") || lower.endsWith(".html"));
}

// find all files that match isHtml in a folder by recursivel`y walking
// the folder
function findHtml(folder) {
    if (!fs.existsSync(folder)) {
        console.log("Could not find folder: ", folder);
        return;
    }
    var files = fs.readdirSync(folder);
    var htmls = [];
    for (var i = 0; i < files.length; i++) {
        var filename = path.join(folder, files[i]);
        var stat = fs.lstatSync(filename);
        if (stat.isDirectory() && !DIRS_TO_SKIP.includes(stat)) {
            var recursed = findHtml(filename);
            for (var j = 0; j < recursed.length; j++) {
                recursed[j] = path.join(files[i], recursed[j]).replace(/\\/g, "/");
            }
            htmls.push.apply(htmls, recursed);
        }
        else if (isHtml(filename)) {
            htmls.push(files[i]);
        };
    };
    return htmls;
}

// read a HTML file and produce a JSON representation containing the path
// to the document, the title and the body
function readHtml(root, file, fileId) {
    var filename = path.join(root, file);
    var txt = fs.readFileSync(filename).toString();

    // parse the content and discard tags which are likely irrelevant
    var $ = cheerio.load(txt);
    var title = $("title").text();
    if (typeof title == 'undefined') title = file;

    TAGS_TO_SKIP.forEach((e) => $(e).remove())

    var body = $("body").text()
    if (typeof body == 'undefined') body = "";
    // discard math which will be between \\[...\\]
    body = body.replace(/\\\[[\s\S]*?\\\]/g, '')

    var data = {
        "id": fileId,
        "l": filename,
        "t": title,
        "b": body
    }
    return data;
}

// call the LUNR index builder
function buildIndex(docs) {
    var idx = lunr(function () {
        this.ref('id');
        this.field('t', { boost: 100 }); // title
        this.field('b'); // body
        docs.forEach(function (doc) {
            this.add(doc);
        }, this);
    });
    return idx;
}

// generate previews for each indexed document (just the title here)
function buildPreviews(docs) {
    var result = {};
    for (var i = 0; i < docs.length; i++) {
        var doc = docs[i];
        result[doc["id"]] = {
            "t": doc["t"],
            "l": doc["l"].replace(/^\.\.\/\.\.\/__site/gi, '/' + path_prefix)
        }
    }
    return result;
}


function main() {
    var htmlFolder = "__site"
    files = findHtml(htmlFolder);
    var docs = [];
    for (var i = 0; i < files.length; i++) {
        docs.push(readHtml(htmlFolder, files[i], i));
    }
    var idx = buildIndex(docs);
    var prev = buildPreviews(docs);
    var js = "const LUNR_DATA = " + JSON.stringify(idx) + ";\n" +
        "const PREVIEW_LOOKUP = " + JSON.stringify(prev) + ";";

    fs.mkdirSync(path.dirname(OUTPUT_INDEX), { recursive: true })
    fs.writeFile(OUTPUT_INDEX, js, function (err) {
        if (err) {
            return console.log(err);
        }
    });
}

main();