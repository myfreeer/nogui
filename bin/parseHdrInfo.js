'use strict';

// export hdr info for x265 or libx265 (ffmpeg)
// R: x=0.000000 y=0.000000, G: x=0.000000 y=0.000000, B: x=0.000000 y=0.000000, White point: x=0.000000 y=0.000000
function parseMasteringDisplay_ColorPrimaries(str) {
    var arr = str.split(',').map(function (e) {
        return e.trim().split(/: x=|y=/).map(function (f) {
            if ((Number(f) === 0) || Number(f))
                return Number(f) * 50000;
            else return f.trim();
        });
    });
    var obj = {};
    for (var i = 0; i < arr.length; i++)
        if (arr[i][0] && (arr[i][1] || arr[i][1] === 0) && (arr[i][2] || arr[i][2] === 0))
            obj[arr[i][0]] = arr[i][1] + ',' + arr[i][2];
    if (obj.R && obj.B && obj.G && obj['White point'])
        return 'G(' + obj.G + ')B(' + obj.B + ')R(' + obj.R + ')WP(' + obj['White point'] + ')';
    return;
}

// parses mediainfo output with argument
// --Output="Video;%colour_range%\n%transfer_characteristics%\n%colour_primaries%\n%matrix_coefficients%\n%MasteringDisplay_ColorPrimaries%\n%MasteringDisplay_Luminance%\n%MaxCLL%\n%MaxFALL%\n%ChromaSubsampling_Position%"
function parseHdrInfo(info, type) {
    var infoArr = info.split('\n').map(function (e) {
        return e.trim();
    });
    if (!(infoArr[1] && (infoArr[1] === 'PQ' || infoArr[1] === 'SMPTE ST 2084') && infoArr[4] && infoArr[5]))
        return ''; // not a hdr video
    var opts = {};
    if (infoArr[0]) { //range
        if (infoArr[0] == 'Limited') opts.range = 'limited';
        else if (infoArr[0] == 'Full') opts.range = 'full';
    }
    if (infoArr[1] === 'PQ' || infoArr[1] === 'SMPTE ST 2084') opts.transfer = 'smpte2084';
    if (infoArr[2]) //colorprim
        switch (infoArr[2]) {
        case "BT.709":
            {
                opts.colorprim = 'bt709';
                break;
            }
        case "BT.470 System M":
            {
                opts.colorprim = 'bt470m';
                break;
            }
        case "SMPTE 240M":
            {
                opts.colorprim = 'smpte240m';
                break;
            }
        case "Generic film":
            {
                opts.colorprim = 'film';
                break;
            }
        case "BT.2020":
            {
                opts.colorprim = 'bt2020';
                break;
            }
        }
    if (infoArr[3]) // colormatrix
        switch (infoArr[3]) {
        case "YCgCo":
            {
                opts.colormatrix = 'YCgCo';
                break;
            }
        case "BT.2020 non-constant":
            {
                opts.colormatrix = 'bt2020nc';
                break;
            }
        case "BT.2020 constant":
            {
                opts.colormatrix = 'bt2020c';
                break;
            }
        case "Chromaticity-derived non-constant":
            {
                opts.colormatrix = '"chroma-derived-nc"';
                break;
            }
        case "Chromaticity-derived constant":
            {
                opts.colormatrix = '"chroma-derived-c"';
                break;
            }
        case "ICtCp":
            {
                opts.colormatrix = 'ictcp';
                break;
            }
        }
    if (infoArr[4] && infoArr[5]) // master-display 
        try {
            var masteringDisplay_Luminance = infoArr[5].split(',').map(function (e) {
                return 10000 * Number(e.match(/[\d\.]+/));
            }).sort().reverse().join(',');
            if (infoArr[4] === 'Display P3')
                opts['master-display'] = 'G(13250,34500)B(7500,3000)R(34000,16000)WP(15635,16450)L(' + masteringDisplay_Luminance + ')';
            else if (infoArr[4] === 'BT.2020')
                opts['master-display'] = 'G(8500,39850)B(6550,2300)R(35400,14600)WP(15635,16450)L(' + masteringDisplay_Luminance + ')';
            else {
                var masteringDisplay_ColorPrimaries = parseMasteringDisplay_ColorPrimaries(infoArr[4]);
                if (masteringDisplay_ColorPrimaries)
                    opts['master-display'] = masteringDisplay_ColorPrimaries + 'L(' + masteringDisplay_Luminance + ')';
            }
        } catch (e) {
            delete opts['master-display'];
        }
    if (infoArr[6] && infoArr[7]) { // max-cll
        var maxCLL = Number(infoArr[6].match(/[\d\.]+/)),
            maxFALL = Number(infoArr[7].match(/[\d\.]+/));
        if (maxCLL && maxFALL)
            opts['max-cll'] = '"' + maxCLL + ',' + maxFALL + '"';
    }
    if (infoArr[8]) { //chromaloc
        var chromaloc;
        if (chromaloc = Number(infoArr[8].match(/[0-5]/)))
            opts.chromaloc = chromaloc;
    }

    if (type === 'x265')
        return Object.keys(opts).map(function (e) {
            return '--' + e + ' ' + opts[e];
        }).join(' ');
    else if (type === 'libx265' || type === 'ffmpeg')
        return Object.keys(opts).map(function (e) {
            return e + '=' + opts[e];
        }).join(':');
    else return opts; // for debug only
}

var str = read('tmp/hdrinfo.txt');
//print(str);
if (str) print(parseHdrInfo(str,'ffmpeg'));