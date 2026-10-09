import AppKit
let root=CommandLine.arguments[1]
let font=try String(contentsOfFile:root+"/rover/font52.fnt",encoding:.utf8)
let atlas=NSImage(contentsOfFile:root+"/rover/font52.png")!.cgImage(forProposedRect:nil,context:nil,hints:nil)!
var glyphs:[Int:[String:Int]]=[:]
for line in font.components(separatedBy:.newlines) where line.hasPrefix("char id=") {
 var values:[String:Int]=[:]
 for part in line.components(separatedBy:.whitespaces).filter({ !$0.isEmpty }) {
  let pair=part.split(separator:"="); if pair.count==2, let v=Int(pair[1]) { values[String(pair[0])]=v }
 }
 glyphs[values["id"]!]=values
}
for (caption,name) in [("record gameplay","RecordGameplayLabel"),("music volume","MusicVolumeLabel"),("effect volume","EffectVolumeLabel")] {
let w=600,h=80
let ctx=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.setShadow(offset:.zero,blur:14,color:CGColor(red:0,green:0.5,blue:1,alpha:1))
ctx.beginTransparencyLayer(auxiliaryInfo:nil)
var x=14
for scalar in caption.unicodeScalars {
 let g=glyphs[Int(scalar.value)]!
 let gw=g["width"]!,gh=g["height"]!
 if gw>0 && gh>0 {
  let crop=atlas.cropping(to:CGRect(x:g["x"]!,y:g["y"]!,width:gw,height:gh))!
  ctx.draw(crop,in:CGRect(x:x+g["xoffset"]!,y:14+52-g["yoffset"]!-gh,width:gw,height:gh))
 }
 x+=37
}
ctx.endTransparencyLayer()
let image=ctx.makeImage()!
let rep=NSBitmapImageRep(cgImage:image)
try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:root+"/mac/Assets/"+name+".png"))

}
