# pdfstamp
Overlays (actually underlays) a given pdf with text and/or date in big red, toned down letters.

## My usecase
I'd like to mark invoices as paid and mark draft drawings as such in an easy manner.

## Known bugs
- The 'underlay' feature, will put the text _behind_ the page content. That means, images and stuff might hide the underlaying stamp. I'd like it to 'overlay' the content of the pdf, but I can't figure out transparency in postscript.
