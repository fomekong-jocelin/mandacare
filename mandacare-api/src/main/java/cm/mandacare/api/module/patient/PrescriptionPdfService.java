package cm.mandacare.api.module.patient;

import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.pdf.*;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

@Service
class PrescriptionPdfService {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy")
            .withZone(ZoneId.systemDefault());

    public byte[] generatePdf(PrescriptionEntity prescription) {
        // Margins: Left 40, Right 40, Top 45, Bottom 70 (gives safe space for footer background curves)
        Document document = new Document(PageSize.A4, 40, 40, 45, 75);
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        try {
            PdfWriter writer = PdfWriter.getInstance(document, out);
            
            // Register page event for beautiful footer waves and leaf logo
            writer.setPageEvent(new PdfPageEventHelper() {
                @Override
                public void onEndPage(PdfWriter writer, Document document) {
                    PdfContentByte cb = writer.getDirectContent();
                    cb.saveState();
                    
                    float width = document.getPageSize().getWidth();
                    
                    // 1. Bottom Dark Blue Wave
                    cb.setColorFill(new Color(11, 59, 96)); // Deep Health Blue
                    cb.moveTo(0, 0);
                    cb.lineTo(0, 20);
                    cb.curveTo(width * 0.25f, 32, width * 0.5f, 15, width * 0.75f, 0);
                    cb.lineTo(0, 0);
                    cb.fill();
                    
                    // 2. Bottom Green Wave
                    cb.setColorFill(new Color(46, 125, 50)); // Medical Green
                    cb.moveTo(width * 0.45f, 0);
                    cb.curveTo(width * 0.6f, 12, width * 0.8f, 25, width, 35);
                    cb.lineTo(width, 0);
                    cb.lineTo(width * 0.45f, 0);
                    cb.fill();
                    
                    // 3. Draw Leaf at the bottom right corner (on top of the waves)
                    cb.setColorFill(new Color(76, 175, 80)); // Leaf Green
                    float lx = width - 40;
                    float ly = 32;
                    cb.moveTo(lx, ly);
                    cb.curveTo(lx - 8, ly + 10, lx, ly + 22, lx + 12, ly + 25);
                    cb.curveTo(lx + 15, ly + 15, lx + 8, ly + 5, lx, ly);
                    cb.fill();
                    
                    // Draw stem/vein in the leaf
                    cb.setColorStroke(Color.WHITE);
                    cb.setLineWidth(1f);
                    cb.moveTo(lx, ly);
                    cb.lineTo(lx + 12, ly + 25);
                    cb.stroke();
                    
                    cb.restoreState();
                }
            });

            document.open();

            // 1. Header (Clinic logo / Branding)
            PdfPTable headerTable = new PdfPTable(2);
            headerTable.setWidthPercentage(100);
            headerTable.setWidths(new float[]{70, 30});
            headerTable.setSpacingAfter(15);

            PdfPCell cellLeft = new PdfPCell();
            cellLeft.setBorder(Rectangle.NO_BORDER);
            
            // Try loading the official horizontal brand logo
            try {
                var logoUrl = getClass().getResource("/assets/brand/mandacare_logo_horizontal.png");
                if (logoUrl != null) {
                    Image logo = Image.getInstance(logoUrl);
                    logo.scalePercent(15f); // Scale to fit nicely (roughly 150 points width)
                    cellLeft.addElement(logo);
                } else {
                    // Fallback to stylized text
                    Font brandFont = new Font(Font.HELVETICA, 20, Font.BOLD, new Color(11, 59, 96));
                    Font subBrandFont = new Font(Font.HELVETICA, 10, Font.ITALIC, new Color(46, 125, 50));
                    cellLeft.addElement(new Paragraph("MandaCare", brandFont));
                    cellLeft.addElement(new Paragraph("Soigner mieux, gérer simplement.", subBrandFont));
                }
            } catch (Exception e) {
                // Fallback to stylized text
                Font brandFont = new Font(Font.HELVETICA, 20, Font.BOLD, new Color(11, 59, 96));
                Font subBrandFont = new Font(Font.HELVETICA, 10, Font.ITALIC, new Color(46, 125, 50));
                cellLeft.addElement(new Paragraph("MandaCare", brandFont));
                cellLeft.addElement(new Paragraph("Soigner mieux, gérer simplement.", subBrandFont));
            }
            headerTable.addCell(cellLeft);

            // Right side: Medical Cross outline icon
            PdfPCell cellRight = new PdfPCell();
            cellRight.setBorder(Rectangle.NO_BORDER);
            cellRight.setCellEvent(new MedicalCrossCellEvent());
            headerTable.addCell(cellRight);

            document.add(headerTable);

            // 2. Title Section ("Ordonnance" and details)
            PdfPTable titleTable = new PdfPTable(2);
            titleTable.setWidthPercentage(100);
            titleTable.setWidths(new float[]{60, 40});
            titleTable.setSpacingAfter(20);

            // Left side: Title with a short green underline
            Font titleFont = new Font(Font.HELVETICA, 22, Font.BOLD, new Color(11, 59, 96));
            PdfPCell titleCell = new PdfPCell(new Paragraph("Ordonnance", titleFont));
            titleCell.setBorder(Rectangle.NO_BORDER);
            titleCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            titleCell.setCellEvent(new GreenUnderlineCellEvent());
            titleTable.addCell(titleCell);

            // Right side: Date and number
            Font metaLabelFont = new Font(Font.HELVETICA, 10, Font.BOLD, new Color(100, 100, 100));
            Font metaValueFont = new Font(Font.HELVETICA, 10, Font.NORMAL, new Color(50, 50, 50));
            
            PdfPCell metaCell = new PdfPCell();
            metaCell.setBorder(Rectangle.NO_BORDER);
            metaCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            
            Paragraph metaPara = new Paragraph();
            metaPara.setLeading(14f);
            metaPara.setAlignment(Element.ALIGN_RIGHT);
            metaPara.add(new Chunk("Date : ", metaLabelFont));
            metaPara.add(new Chunk(DATE_FORMATTER.format(prescription.createdAt()) + "\n", metaValueFont));
            metaPara.add(new Chunk("N° Ordonnance : ", metaLabelFont));
            metaPara.add(new Chunk(prescription.prescriptionNumber(), metaValueFont));
            
            metaCell.addElement(metaPara);
            titleTable.addCell(metaCell);

            document.add(titleTable);

            // 3. Patient & Doctor Info Card (Rounded Light Gray Card)
            PatientEntity patient = prescription.patient();
            String patientName = patient.firstName() + " " + patient.lastName();
            String sex = patient.sex() != null ? patient.sex().name() : "-";
            String birthOrAge = patient.birthDate() != null 
                    ? patient.birthDate().toString() 
                    : (patient.declaredAge() != null ? patient.declaredAge() + " ans" : "-");

            Font infoHeaderFont = new Font(Font.HELVETICA, 10, Font.BOLD, new Color(11, 59, 96));
            Font infoValFont = new Font(Font.HELVETICA, 10, Font.NORMAL, new Color(60, 60, 60));

            PdfPTable infoCardTable = new PdfPTable(1);
            infoCardTable.setWidthPercentage(100);
            infoCardTable.setSpacingAfter(25);

            PdfPCell cardCell = new PdfPCell();
            cardCell.setPadding(12);
            cardCell.setBorder(Rectangle.NO_BORDER);
            cardCell.setCellEvent(new RoundedBorderCellEvent());

            PdfPTable innerInfo = new PdfPTable(3);
            innerInfo.setWidthPercentage(100);
            innerInfo.setWidths(new float[]{10, 45, 45});

            // Column 1: User Vector Icon
            PdfPCell iconCell = new PdfPCell();
            iconCell.setBorder(Rectangle.NO_BORDER);
            iconCell.setCellEvent(new UserIconCellEvent());
            innerInfo.addCell(iconCell);

            // Column 2: Patient Info
            PdfPCell patientDetailsCell = new PdfPCell();
            patientDetailsCell.setBorder(Rectangle.NO_BORDER);
            Paragraph pDetails = new Paragraph();
            pDetails.setLeading(16f);
            pDetails.add(new Chunk("Patient : ", infoHeaderFont));
            pDetails.add(new Chunk(patientName + "\n", infoValFont));
            pDetails.add(new Chunk("Âge / Sexe : ", infoHeaderFont));
            pDetails.add(new Chunk(birthOrAge + " / " + sex + "\n", infoValFont));
            pDetails.add(new Chunk("ID Patient : ", infoHeaderFont));
            pDetails.add(new Chunk(patient.id().toString().substring(0, 8).toUpperCase() + "\n", infoValFont));
            patientDetailsCell.addElement(pDetails);
            innerInfo.addCell(patientDetailsCell);

            // Column 3: Doctor Info
            PdfPCell doctorDetailsCell = new PdfPCell();
            doctorDetailsCell.setBorder(Rectangle.NO_BORDER);
            Paragraph dDetails = new Paragraph();
            dDetails.setLeading(16f);
            dDetails.add(new Chunk("Médecin : ", infoHeaderFont));
            dDetails.add(new Chunk("Dr Manda\n", infoValFont));
            dDetails.add(new Chunk("Spécialité : ", infoHeaderFont));
            dDetails.add(new Chunk("Généraliste\n", infoValFont));
            dDetails.add(new Chunk("Contact : ", infoHeaderFont));
            dDetails.add(new Chunk("+237 691 501 780\n", infoValFont));
            doctorDetailsCell.addElement(dDetails);
            innerInfo.addCell(doctorDetailsCell);

            cardCell.addElement(innerInfo);
            infoCardTable.addCell(cardCell);
            document.add(infoCardTable);

            // 4. Rx Prescription Box
            PdfPTable rxOuterTable = new PdfPTable(1);
            rxOuterTable.setWidthPercentage(100);
            
            PdfPCell rxOuterCell = new PdfPCell();
            rxOuterCell.setPadding(25);
            rxOuterCell.setPaddingTop(35); // leaves room for the Rx watermark
            rxOuterCell.setBorder(Rectangle.NO_BORDER);
            rxOuterCell.setCellEvent(new RxBoxCellEvent());

            // Inner drugs list table
            PdfPTable drugsTable = new PdfPTable(1);
            drugsTable.setWidthPercentage(100);

            if (prescription.items().isEmpty()) {
                PdfPCell emptyCell = new PdfPCell(new Paragraph("Aucun médicament prescrit dans cette ordonnance.", new Font(Font.HELVETICA, 10, Font.ITALIC, new Color(120, 120, 120))));
                emptyCell.setBorder(Rectangle.NO_BORDER);
                emptyCell.setPadding(15);
                emptyCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                drugsTable.addCell(emptyCell);
            } else {
                for (PrescriptionItemEntity item : prescription.items()) {
                    PdfPCell drugCell = new PdfPCell();
                    drugCell.setBorder(Rectangle.NO_BORDER);
                    drugCell.setCellEvent(new BottomLineCellEvent());
                    drugCell.setPaddingBottom(12);
                    drugCell.setPaddingTop(12);

                    Paragraph drugPara = new Paragraph();
                    drugPara.setLeading(17f);
                    
                    // 1. Drug name & Form
                    drugPara.add(new Chunk(item.drugName(), new Font(Font.HELVETICA, 11, Font.BOLD, new Color(11, 59, 96))));
                    if (item.form() != null) {
                        drugPara.add(new Chunk(" (" + item.form() + ")", new Font(Font.HELVETICA, 10, Font.ITALIC, new Color(100, 100, 100))));
                    }
                    drugPara.add(new Chunk("\n"));

                    // 2. Dosage / Frequency / Duration / Qty
                    String posologyStr = "";
                    if (item.dosage() != null) posologyStr += "Dosage : " + item.dosage();
                    if (item.frequency() != null) {
                        if (!posologyStr.isEmpty()) posologyStr += "   |   ";
                        posologyStr += "Fréquence : " + item.frequency();
                    }
                    if (item.duration() != null) {
                        if (!posologyStr.isEmpty()) posologyStr += "   |   ";
                        posologyStr += "Durée : " + item.duration();
                    }
                    if (item.quantity() != null) {
                        if (!posologyStr.isEmpty()) posologyStr += "   |   ";
                        posologyStr += "Qté : " + item.quantity() + " boîte(s)";
                    }
                    
                    if (!posologyStr.isEmpty()) {
                        drugPara.add(new Chunk(posologyStr + "\n", new Font(Font.HELVETICA, 9.5f, Font.NORMAL, new Color(60, 60, 60))));
                    }

                    // 3. Instructions
                    if (item.instructions() != null && !item.instructions().isEmpty()) {
                        drugPara.add(new Chunk("Instructions : ", new Font(Font.HELVETICA, 9.5f, Font.BOLD, new Color(100, 100, 100))));
                        drugPara.add(new Chunk(item.instructions(), new Font(Font.HELVETICA, 9.5f, Font.ITALIC, new Color(80, 80, 80))));
                    }

                    drugCell.addElement(drugPara);
                    drugsTable.addCell(drugCell);
                }
            }

            rxOuterCell.addElement(drugsTable);

            // 5. Signature area at the bottom-right of the Rx box
            PdfPTable signatureTable = new PdfPTable(2);
            signatureTable.setWidthPercentage(100);
            signatureTable.setWidths(new float[]{60, 40});

            PdfPCell leftSig = new PdfPCell();
            leftSig.setBorder(Rectangle.NO_BORDER);
            signatureTable.addCell(leftSig);

            PdfPCell rightSig = new PdfPCell();
            rightSig.setBorder(Rectangle.NO_BORDER);
            rightSig.setPaddingTop(40);
            rightSig.setPaddingRight(10);
            
            Paragraph sigPara = new Paragraph();
            sigPara.setAlignment(Element.ALIGN_RIGHT);
            sigPara.setLeading(14f);
            sigPara.add(new Chunk("Signature & Cachet\n", new Font(Font.HELVETICA, 10, Font.BOLD, new Color(11, 59, 96))));
            sigPara.add(new Chunk("_____________________\n", new Font(Font.HELVETICA, 10, Font.NORMAL, new Color(11, 59, 96))));
            
            rightSig.addElement(sigPara);
            signatureTable.addCell(rightSig);
            
            rxOuterCell.addElement(signatureTable);
            rxOuterTable.addCell(rxOuterCell);
            
            document.add(rxOuterTable);

            document.close();
        } catch (Exception e) {
            throw new RuntimeException("Erreur de génération de l'ordonnance en PDF", e);
        }

        return out.toByteArray();
    }

    // --- Private Static Events & Helpers for Drawing ---

    private static class MedicalCrossCellEvent implements PdfPCellEvent {
        @Override
        public void cellLayout(PdfPCell cell, Rectangle position, PdfContentByte[] canvases) {
            PdfContentByte cb = canvases[PdfPTable.BACKGROUNDCANVAS];
            cb.saveState();
            cb.setColorStroke(new Color(76, 175, 80)); // Green outline
            cb.setLineWidth(1.5f);
            
            float width = 30f;
            float height = 30f;
            float cx = position.getRight() - 25f;
            float cy = position.getTop() - height/2 - 10f;
            
            float arm = 10f; // Thickness of the cross bars
            
            // Draw cross outline
            cb.moveTo(cx - arm/2, cy + height/2);
            cb.lineTo(cx + arm/2, cy + height/2);
            cb.lineTo(cx + arm/2, cy + arm/2);
            cb.lineTo(cx + width/2, cy + arm/2);
            cb.lineTo(cx + width/2, cy - arm/2);
            cb.lineTo(cx + arm/2, cy - arm/2);
            cb.lineTo(cx + arm/2, cy - height/2);
            cb.lineTo(cx - arm/2, cy - height/2);
            cb.lineTo(cx - arm/2, cy - arm/2);
            cb.lineTo(cx - width/2, cy - arm/2);
            cb.lineTo(cx - width/2, cy + arm/2);
            cb.lineTo(cx - arm/2, cy + arm/2);
            cb.closePath();
            cb.stroke();
            
            cb.restoreState();
        }
    }

    private static class GreenUnderlineCellEvent implements PdfPCellEvent {
        @Override
        public void cellLayout(PdfPCell cell, Rectangle position, PdfContentByte[] canvases) {
            PdfContentByte cb = canvases[PdfPTable.BACKGROUNDCANVAS];
            cb.saveState();
            cb.setColorStroke(new Color(46, 125, 50)); // Medical Green
            cb.setLineWidth(3f);
            cb.moveTo(position.getLeft(), position.getBottom() - 4);
            cb.lineTo(position.getLeft() + 35, position.getBottom() - 4); // Short decorative line
            cb.stroke();
            cb.restoreState();
        }
    }

    private static class RoundedBorderCellEvent implements PdfPCellEvent {
        @Override
        public void cellLayout(PdfPCell cell, Rectangle position, PdfContentByte[] canvases) {
            PdfContentByte cb = canvases[PdfPTable.BACKGROUNDCANVAS];
            cb.saveState();
            cb.setColorFill(new Color(248, 250, 252)); // Light gray-blue background
            cb.setColorStroke(new Color(225, 230, 235)); // Soft border
            cb.setLineWidth(1f);
            cb.roundRectangle(
                position.getLeft(), 
                position.getBottom(), 
                position.getWidth(), 
                position.getHeight(), 
                10f // corner radius
            );
            cb.fillStroke();
            cb.restoreState();
        }
    }

    private static class UserIconCellEvent implements PdfPCellEvent {
        @Override
        public void cellLayout(PdfPCell cell, Rectangle position, PdfContentByte[] canvases) {
            PdfContentByte cb = canvases[PdfPTable.BACKGROUNDCANVAS];
            cb.saveState();
            cb.setColorStroke(new Color(76, 175, 80)); // Leaf Green
            cb.setLineWidth(1.5f);
            
            float cx = position.getLeft() + 15f;
            float cy = position.getTop() - 22f;
            
            // Head: circle with radius 5.5
            cb.circle(cx, cy + 8, 5.5f);
            cb.stroke();
            
            // Shoulders: arc
            cb.moveTo(cx - 9, cy - 8);
            cb.curveTo(cx - 9, cy, cx + 9, cy, cx + 9, cy - 8);
            cb.stroke();
            
            cb.restoreState();
        }
    }

    private static class RxBoxCellEvent implements PdfPCellEvent {
        @Override
        public void cellLayout(PdfPCell cell, Rectangle position, PdfContentByte[] canvases) {
            PdfContentByte cb = canvases[PdfPTable.BACKGROUNDCANVAS];
            cb.saveState();
            
            // 1. Draw outer rounded border with white background
            cb.setColorFill(Color.WHITE);
            cb.setColorStroke(new Color(215, 220, 225));
            cb.setLineWidth(1f);
            cb.roundRectangle(
                position.getLeft(), 
                position.getBottom(), 
                position.getWidth(), 
                position.getHeight(), 
                12f // corner radius
            );
            cb.fillStroke();
            
            // 2. Draw faded "Rx" watermark in the top-left corner of the box
            try {
                BaseFont bf = BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED);
                cb.setFontAndSize(bf, 36);
                cb.setColorFill(new Color(235, 240, 244)); // Very light blue-gray watermark
                cb.beginText();
                cb.showTextAligned(PdfContentByte.ALIGN_LEFT, "Rx", position.getLeft() + 18, position.getTop() - 40, 0);
                cb.endText();
            } catch (Exception e) {
                // Ignore watermark errors
            }
            
            cb.restoreState();
        }
    }

    private static class BottomLineCellEvent implements PdfPCellEvent {
        @Override
        public void cellLayout(PdfPCell cell, Rectangle position, PdfContentByte[] canvases) {
            PdfContentByte cb = canvases[PdfPTable.BACKGROUNDCANVAS];
            cb.saveState();
            cb.setColorStroke(new Color(235, 238, 242)); // Light notebook-style divider
            cb.setLineWidth(1f);
            cb.moveTo(position.getLeft(), position.getBottom());
            cb.lineTo(position.getRight(), position.getBottom());
            cb.stroke();
            cb.restoreState();
        }
    }
}
