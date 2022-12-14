// This file is adapted from the un-licensed repo
// https://github.com/BLE-LTER/Lunr-Index-and-Search-for-Static-Sites

var path = require("path");
var fs = require("fs");
var lunr = require("lunr");
var cheerio = require("cheerio");

// makes the assumption that we have the folder structure as
// __site/
// _libs/
//      lunr/
//          build_index.js
// so that ../../__site makes sense.
// 
// if you placed the build_index.js somewhere else, adjust this accordingly.
const HTML_FOLDER = "../../__site";


// ----------------------------------------------------------------------------
// 
// Index builder, you shouldn't have to modify this code unless you
// want a customised index. 
// 
// Process (see main)
//      1. look for all html files to scrape in __site (see main, findHtml)
//      2. recover their path, title and body and make a dictionary with
//          that (see main, readHtml)
//      3. build a lunr index out of that (see build_index)
//      4. build a preview dictionary for each index page
//      5. write all this to a file that the lunr client can process
// 
// ----------------------------------------------------------------------------

const OUTPUT_INDEX = "lunr_index.js";
const DO_NOT_INDEX = ["assets", "css", "libs"];

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
        if (stat.isDirectory() && !DO_NOT_INDEX.includes(stat)) {
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
    var $ = cheerio.load(txt);
    var title = $("title").text();
    if (typeof title == 'undefined') title = file;
    var body = $("body").text()
    if (typeof body == 'undefined') body = "";

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
        this.field('t'); // title
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
            "l": doc["l"].replace(/^\.\.\/\.\.\/__site/gi, '/' + PATH_PREPEND)
        }
    }
    return result;
}


function main() {
    files = findHtml(HTML_FOLDER);
    var docs = [];
    for (var i = 0; i < files.length; i++) {
        docs.push(readHtml(HTML_FOLDER, files[i], i));
    }
    var idx = buildIndex(docs);
    var prev = buildPreviews(docs);
    var js = "const LUNR_DATA = " + JSON.stringify(idx) + ";\n" +
        "const PREVIEW_LOOKUP = " + JSON.stringify(prev) + ";";
    fs.writeFile(OUTPUT_INDEX, js, function (err) {
        if (err) {
            return console.log(err);
        }
    });
}

main();