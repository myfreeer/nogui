'use strict';

var mapColorPrim = {
    "BT.709": 'bt709',
    "BT.470 System M": 'bt470m',
    "BT.601 NTSC": 'smpte240m',
    "SMPTE 240M": 'smpte240m',
    "Generic film": 'film',
    "BT.2020": 'bt2020'
};

var mapTransfer = {
    "YCgCo": 'YCgCo',
    "Linear": 'linear',
    "SMPTE 240M": 'smpte240m',
    "SMPTE 428M": 'smpte428',
    "BT.2020 (12-bit)": 'bt2020-12',
    "BT.2020 (10-bit)": 'bt2020-10',
    "Logarithmic (100:1)": 'log100',
    "Logarithmic (316.22777:1)": 'log316',
    "PQ": 'smpte2084',
    "SMPTE ST 2084": 'smpte2084'
};

var mapMatrix = {
    "YCgCo": 'YCgCo',
    "BT.2020 non-constant": 'bt2020nc',
    "BT.2020 constant": 'bt2020c',
    "Chromaticity-derived non-constant": 'chroma-derived-nc',
    "Chromaticity-derived constant": 'chroma-derived-c',
    "ICtCp": 'ictcp'
};

var mapColorPrimaries = {
    "BT.709": "G(30000,15000)B(7500,3000)R(32000,16500)WP(15635,16450)",
    'Display P3': 'G(13250,34500)B(7500,3000)R(34000,16000)WP(15635,16450)',
    'BT.2020': 'G(8500,39850)B(6550,2300)R(35400,14600)WP(15635,16450)'
};

var getNumber = function getNumber(str) {
    if (!(str && str.match)) return;
    return Number(str.match(/[\d\.]+/));
};

var formatMasterDisplay = function formatMasterDisplay(color, luminance) {
    if (!color || !luminance) return;
    var str = mapColorPrimaries[color];
    if (!str) {
        color = color.replace(/White point/ig, "WP");
        var obj = {};
        color.split(',').map(function (e) {
            return e.trim().split(/: x=|y=/).map(function (f) {
                return isNaN(+f) ? f.trim() : Math.round(50000 * f);
            });
        }).forEach(function (e) {
            return obj[e[0]] = e[0] + '(' + e[1] + ',' + e[2] + ')';
        });
        str = obj.G + obj.B + obj.R + obj.WP;
    }
    str += 'L(' + luminance.split(',').map(function (e) {
        return 10000 * e.match(/[\d\.]+/);
    }).sort().join(',') + ')';
    if (!/^G\(\d+,\d+\)B\(\d+,\d+\)R\(\d+,\d+\)WP\(\d+,\d+\)L\(\d+,\d+\)$/.test(str)) return;
    return str;
};

var formatMaxCLL = function formatMaxCLL() {
    var maxCLL = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';
    var maxFALL = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : '';

    if (!maxCLL || !maxFALL) return;
    return getNumber(maxCLL) + ',' + getNumber(maxFALL);
};

var parseHdrInfo = function parseHdrInfo() {
    var info = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';
    var type = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : '';

    var infoArr = info.split('\n').map(function (e) {
        return e.trim();
    });
    var obj = {
        range: infoArr[0] && infoArr[0].toLowerCase(),
        transfer: mapTransfer[infoArr[1]],
        colorprim: mapColorPrim[infoArr[2]],
        colormatrix: mapMatrix[infoArr[3]],
        "master-display": formatMasterDisplay(infoArr[4], infoArr[5]),
        'max-cll': formatMaxCLL(infoArr[6], infoArr[7]),
        chromaloc: getNumber(infoArr[8])
    };
    if (obj.transfer !== 'smpte2084') return; // not hdr
    var options = {};
    for (var i in obj) {
        if (obj[i]) options[i] = obj[i];
    }switch (type.toLowerCase()) {
        case 'x265':
        case 'cil':
            return Object.keys(options).map(function (e) {
                return '--' + e + ' ' + options[e];
            }).join(' ') + ' --hdr --hdr-opt';
        case 'libx265':
        case 'ffmpeg':
        case 'libav':
            return Object.keys(options).map(function (e) {
                return e + '=' + options[e];
            }).join(':') + ':hdr=1:hdr-opt=1';
    }
    return options; // for debug only
};

var str = read('tmp/hdrinfo.txt');
//print(str);
if (str) print(parseHdrInfo(str,'ffmpeg'));