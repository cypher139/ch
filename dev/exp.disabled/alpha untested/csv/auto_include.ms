export('csvim.version', '1.0')

proc _csv_importer(@filename, @option1, @option2) {
@file = ''
try {
    @file = read(@filename)
} catch(NotFoundException @ex) {
    die(color(7).'['.color(6).'CSV Import'.color(7).'] '.'Cannot read specified file. Make sure to type the file path correctly.')
} catch(Exception @ex) {
    die(color(7).'['.color(6).'CSV Import'.color(7).'] '.@ex['message'])
}
return(@file)
}
