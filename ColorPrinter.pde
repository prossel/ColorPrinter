// This sketch constantly monitor the downloads folder and when a new file is added, check if matches the pattern ("date time palette 012 234 567 890.svc,
// it will be copied to the specified folder, then
// a pdf will be created and saved in the same folder with the same name as the palette.svg file, then printed.

import processing.pdf.*;
import java.io.File;

String archivesFolder;

// Page size
float cm = 72 / 2.54; // Convert cm to pix at 72 DPI
int pageWidth = round(10.0 * cm);
int pageHeight = round(14.8 * cm);

float marginLeft = 0.5 * cm;
float marginTop = 0.4 * cm;

float previewScale = 2;

PGraphics pgPreview; // One graphics for preview

PShape shape;
PShape shapeLogo;


String paletteFilename;

PFont fontTitle;
PFont fontText;
PFont fontTM;

JSONObject luminance;

void settings() {
  size(round(pageWidth * previewScale), round(pageHeight * previewScale));
}

void setup() {

  background(255);
  println(archivesFolder);

  //   archivesFolder = sketchPath("archives/");
  archivesFolder = palettesFolder + "archives/";

  //Verify if archives folder exists and create it if it doesn't
  File folder = new File(archivesFolder);
  if (!folder.exists()) {
    folder.mkdir();
    println(folder.toPath());
  }

  //load svg file 2024-05-13 185455 Palette 350 070.svg
  //shape = loadShape(palettesFolder + "2024-05-13 185455 Palette 350 070.svg");
  //shape = loadShape(palettesFolder + "Hexagone2.svg");
  //shape = loadShape(palettesFolder + "2024-05-13 200254 Palette 069 220 171 162.svg");
  //shape = loadShape(palettesFolder + "2024-05-13 202302 Palette 850 069 070 862.svg");

  shapeLogo = loadShape("LOGO.svg");

  pgPreview = createGraphics(pageWidth, pageHeight);

  fontTitle = createFont("HankenGrotesk-VariableFont_wght.ttf", 9);
  fontText = createFont("HankenGrotesk-VariableFont_wght.ttf", 6);
  fontTM = createFont("HankenGrotesk-VariableFont_wght.ttf", 4);

  luminance = loadJSONObject("luminance.json");
  //println(luminance);

  //TEST preview
  //paletteFilename = "2024-05-13 202302 PaletteFake 070 820 739 850.svg";
  //shape = loadShape(palettesFolder + paletteFilename);
  //previewPage(paletteFilename);
}


void draw() {

  background(255);

  fill(0);
  textAlign(CENTER, CENTER);
  textSize(30);
  text("Monitoring folder\n\n" + palettesFolder, 0, 0, width, height);

  image(pgPreview, 0, 0, width, height);

  monitorFolder();

  delay(1000);
}

void previewPage(String paletteFilename) {

  //Draw into preview graphic
  pgPreview.beginDraw();
  //pgPreview.scale(previewScale, previewScale);
  pgPreview.colorMode(RGB, 255, 255, 255);
  pgPreview.background(255);
  drawPage(pgPreview, paletteFilename);
  pgPreview.endDraw();
}


String exportPage(String paletteFilename) {
  //page filename is the same as palette, but with .pdf extension
  String pageFilename = paletteFilename.replace(".svg", ".pdf");
  String pagePath = archivesFolder + pageFilename;

  //create PDF forA5 format
  PGraphicsPDF pdf = (PGraphicsPDF) createGraphics(pageWidth, pageHeight, PDF, pagePath);
  pdf.beginDraw();
  drawPage(pdf, paletteFilename);
  pdf.dispose();
  pdf.endDraw();

  pdf = null;

  println("Page saved to " + pagePath);

  return pagePath;
}

void drawPage(PGraphics page, String paletteFilename) {

  // Logo
  page.shapeMode(CORNER);
  float scaleLogo = pageWidth * 0.4 / shapeLogo.width;
  page.shape(shapeLogo, marginLeft, marginTop, shapeLogo.width * scaleLogo, shapeLogo.height * scaleLogo);

  // palette
  page.shapeMode(CENTER);
  float shapeScale = 0.51 / 1.438;
  page.shape(shape, page.width / 2, page.height * 0.4, shape.width * shapeScale, shape.height * shapeScale);

  // Luminance
  page.fill(0);
  page.textFont(fontTitle);
  page.text("LUMINANCE 6901", marginLeft, 0.7 * pageHeight);
  float wLum = page.textWidth("LUMINANCE 6901");
  page.textFont(fontTM);
  page.text("TM", marginLeft + wLum, 0.7 * pageHeight - fontTitle.getSize() * 0.5);

  // Extract the 4 references from filename(ex : 2024 - 05 - 13 202302 Palette 850 069 070 862.svg ->[850, 069, 070, 862])
  String[] parts = splitTokens(paletteFilename.replace(".svg", ""), " ");
  String[] refs = subset(parts, 3, 4);

  // Draw the 4 references
  page.textFont(fontText);
  page.textLeading(fontText.getDefaultSize() * 1.3);
  drawRef(page, refs[0], marginLeft, 0.75 * pageHeight);
  drawRef(page, refs[1], 0.52 * page.width, 0.75 * pageHeight);
  drawRef(page, refs[2], marginLeft, 0.88 * pageHeight);
  drawRef(page, refs[3], 0.52 * page.width, 0.88 * pageHeight);
}

void drawRef(PGraphics page, String ref, float xRef, float yRef) {

  JSONObject refLuminance = luminance.getJSONObject(ref);
  JSONObject hsb = refLuminance.getJSONObject("hsb");

  //Draw the reference
  page.colorMode(HSB, 360, 100, 100);
  //println(hsb.getInt("hue"), hsb.getInt("saturation"), hsb.getInt("brightness"));
  page.fill(0);
  page.text(ref + "\n" + refLuminance.getString("textEnFrDe"), xRef, yRef);

  // color patch
  page.noStroke();
  float textSize = fontText.getDefaultSize();
  page.fill(hsb.getInt("hue"), hsb.getInt("saturation"), hsb.getInt("brightness"));
  page.ellipse(xRef + 3 * textSize, yRef - 0.5 * textSize, textSize * 1.3, textSize * 1.3);
}

void keyPressed() {

  switch(key) {
  case'x':
    exportPage(paletteFilename);
    break;
  case 'm':
    monitorFolder();
    break;
  }
}

void monitorFolder() {
  //println("Monitoring folder " + palettesFolder);

  //Listall files in the downloads folder
  File dir = new File(palettesFolder);
  File[]files = dir.listFiles();

  //Check if there are files in the downloads folder
  if (files.length > 0) {
    //Iterate over all files in the downloads folder
    for (int i = 0; i < files.length; i++) {
      //Check if the file is a file
      if (files[i].isFile()) {
        //Check if the file name matches thepattern
        if (files[i].getName().matches(".*Palette \\d\\d\\d \\d\\d\\d \\d\\d\\d \\d\\d\\d\\.svg")) {

          println(files[i].getName() + " matches the pattern");

          // preview
          paletteFilename = files[i].getName();
          shape = loadShape(palettesFolder + File.separator + paletteFilename);
          previewPage(paletteFilename);

          // export page
          String pagePath = exportPage(paletteFilename);

          // Print the page
          String[]args = new String[0];
          args = append(args, "lp");
          args = append(args, "-o");
          args =append(args, "media=Custom."+ round(pageWidth * 10 / cm) + "x" + round(pageHeight * 10 / cm) + "mm");
          // args = append(args, "-o");
          // args = append(args, "scaling=100");
          args = append(args, pagePath);
          println(join(args, " "));

          if (true) {
            Process p = exec(args);
            //Process p = exec("pwd");

            try {
              int result = p.waitFor();
              println("the process returned " + result);
            }
            catch(InterruptedException e) {
              println(e.toString());
            }
          }

          // Move paletteFilename from palettesFolder to archivesFolder
          File file = new File(palettesFolder + paletteFilename);
          File fileDest = new File(archivesFolder + paletteFilename);
          file.renameTo(fileDest);

          // only process one image at a time to let the main draw display last preview
          return;
        }
      }
    }
  }
  //println("Done");
}
