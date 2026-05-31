package cm.mandacare.api.module.patient;

import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.pdf.*;
import org.springframework.stereotype.Service;
import cm.mandacare.api.module.center.CenterSettingsService;
import cm.mandacare.api.module.center.CenterSettingsResponse;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

@Service
class PrescriptionPdfService {

    private final CenterSettingsService centerSettingsService;

    PrescriptionPdfService(CenterSettingsService centerSettingsService) {
        this.centerSettingsService = centerSettingsService;
    }

    private static final Color DEEP_HEALTH_BLUE = new Color(11, 59, 96);
    private static final Color MEDICAL_GREEN = new Color(46, 125, 50);
    private static final Color TEXT = new Color(60, 60, 60);
    private static final Color MUTED_TEXT = new Color(105, 112, 122);
    private static final Color LIGHT_CARD = new Color(248, 250, 252);
    private static final Color SOFT_BORDER = new Color(225, 230, 235);
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy")
            .withZone(ZoneId.systemDefault());

    public byte[] generatePdf(PrescriptionEntity prescription) {
        final CenterSettingsResponse settings = centerSettingsService.currentSettings();
        Document document = new Document(PageSize.A4, 40, 40, 40, 54);
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
                    cb.setColorFill(DEEP_HEALTH_BLUE);
                    cb.moveTo(0, 0);
                    cb.lineTo(0, 16);
                    cb.curveTo(width * 0.25f, 25, width * 0.5f, 12, width * 0.75f, 0);
                    cb.lineTo(0, 0);
                    cb.fill();
                    
                    cb.setColorFill(MEDICAL_GREEN);
                    cb.moveTo(width * 0.45f, 0);
                    cb.curveTo(width * 0.6f, 9, width * 0.8f, 20, width, 28);
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

                    // 4. Draw Legal Footer Text (RCCM, NIU, BP, etc.) centered above waves
                    StringBuilder sb = new StringBuilder();
                    sb.append(settings.name() != null ? settings.name() : "MandaCare");
                    if (settings.address() != null) sb.append(" - ").append(settings.address());
                    else if (settings.city() != null) sb.append(" - ").append(settings.city());
                    if (settings.phone() != null) sb.append(" - Tél : ").append(settings.phone());
                    if (settings.email() != null) sb.append(" - Email : ").append(settings.email());
                    if (settings.poBox() != null) sb.append(" - BP : ").append(settings.poBox());
                    if (settings.rccm() != null) sb.append(" - RCCM : ").append(settings.rccm());
                    if (settings.taxpayerNumber() != null) sb.append(" - NIU : ").append(settings.taxpayerNumber());

                    Font footerFont = new Font(Font.HELVETICA, 7.5f, Font.NORMAL, MUTED_TEXT);
                    ColumnText.showTextAligned(cb, Element.ALIGN_CENTER, new Phrase(sb.toString(), footerFont), width / 2, 34, 0);
                    
                    cb.restoreState();
                }
            });

            document.open();

            // 1. Header (Clinic logo / Branding)
            PdfPTable headerTable = new PdfPTable(2);
            headerTable.setWidthPercentage(100);
            headerTable.setWidths(new float[]{70, 30});
            headerTable.setSpacingAfter(10);

            PdfPCell cellLeft = new PdfPCell();
            cellLeft.setBorder(Rectangle.NO_BORDER);
            
            // Try loading the official horizontal brand logo
            try {
                var logoUrl = getClass().getResource("/assets/brand/mandacare_logo_horizontal.png");
                if (logoUrl != null) {
                    Image logo = Image.getInstance(logoUrl);
                    logo.scalePercent(13.5f);
                    cellLeft.addElement(logo);
                } else {
                    // Fallback to stylized text
                    Font brandFont = new Font(Font.HELVETICA, 20, Font.BOLD, DEEP_HEALTH_BLUE);
                    Font subBrandFont = new Font(Font.HELVETICA, 10, Font.ITALIC, MEDICAL_GREEN);
                    cellLeft.addElement(new Paragraph("MandaCare", brandFont));
                    cellLeft.addElement(new Paragraph("Soigner mieux, gérer simplement.", subBrandFont));
                }
            } catch (Exception e) {
                // Fallback to stylized text
                Font brandFont = new Font(Font.HELVETICA, 20, Font.BOLD, DEEP_HEALTH_BLUE);
                Font subBrandFont = new Font(Font.HELVETICA, 10, Font.ITALIC, MEDICAL_GREEN);
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
            titleTable.setSpacingAfter(14);

            // Left side: Title with a short green underline
            Font titleFont = new Font(Font.HELVETICA, 20, Font.BOLD, DEEP_HEALTH_BLUE);
            PdfPCell titleCell = new PdfPCell(new Paragraph("Ordonnance", titleFont));
            titleCell.setBorder(Rectangle.NO_BORDER);
            titleCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            titleCell.setCellEvent(new GreenUnderlineCellEvent());
            titleTable.addCell(titleCell);

            // Right side: Date and number
            Font metaLabelFont = new Font(Font.HELVETICA, 9, Font.BOLD, MUTED_TEXT);
            Font metaValueFont = new Font(Font.HELVETICA, 9, Font.NORMAL, TEXT);
            
            PdfPCell metaCell = new PdfPCell();
            metaCell.setBorder(Rectangle.NO_BORDER);
            metaCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            
            Paragraph metaPara = new Paragraph();
            metaPara.setLeading(12.5f);
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

            Font infoHeaderFont = new Font(Font.HELVETICA, 9.2f, Font.BOLD, DEEP_HEALTH_BLUE);
            Font infoValFont = new Font(Font.HELVETICA, 9.2f, Font.NORMAL, TEXT);

            PdfPTable infoCardTable = new PdfPTable(1);
            infoCardTable.setWidthPercentage(100);
            infoCardTable.setSpacingAfter(14);

            PdfPCell cardCell = new PdfPCell();
            cardCell.setPadding(10);
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
            pDetails.setLeading(14f);
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
            dDetails.setLeading(14f);
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

            // 4. Prescription lines. Keep rows splittable to avoid blank pages on long prescriptions.
            Paragraph medicationTitle = new Paragraph(
                    "Médicaments prescrits",
                    new Font(Font.HELVETICA, 11.2f, Font.BOLD, DEEP_HEALTH_BLUE)
            );
            medicationTitle.setSpacingAfter(7);
            document.add(medicationTitle);

            PdfPTable drugsTable = new PdfPTable(4);
            drugsTable.setWidthPercentage(100);
            drugsTable.setWidths(new float[]{30, 27, 18, 25});
            drugsTable.setHeaderRows(1);
            drugsTable.setSplitRows(true);
            drugsTable.setSplitLate(false);
            drugsTable.setSpacingAfter(14);

            drugsTable.addCell(tableHeaderCell("Médicament"));
            drugsTable.addCell(tableHeaderCell("Posologie"));
            drugsTable.addCell(tableHeaderCell("Durée / Qté"));
            drugsTable.addCell(tableHeaderCell("Instructions"));

            if (prescription.items().isEmpty()) {
                PdfPCell emptyCell = tableBodyCell(
                        "Aucun médicament prescrit dans cette ordonnance.",
                        new Font(Font.HELVETICA, 9.5f, Font.ITALIC, MUTED_TEXT),
                        Color.WHITE
                );
                emptyCell.setColspan(4);
                drugsTable.addCell(emptyCell);
            } else {
                boolean alternate = false;
                for (PrescriptionItemEntity item : prescription.items()) {
                    Color rowBg = alternate ? LIGHT_CARD : Color.WHITE;
                    alternate = !alternate;

                    Paragraph drugName = new Paragraph();
                    drugName.setLeading(13f);
                    drugName.add(new Chunk(item.drugName(), new Font(Font.HELVETICA, 9.4f, Font.BOLD, DEEP_HEALTH_BLUE)));
                    if (item.form() != null && !item.form().isBlank()) {
                        drugName.add(new Chunk("\n" + item.form(), new Font(Font.HELVETICA, 8.8f, Font.ITALIC, MUTED_TEXT)));
                    }

                    drugsTable.addCell(tableBodyCell(drugName, rowBg));
                    drugsTable.addCell(tableBodyCell(posology(item), new Font(Font.HELVETICA, 9.2f, Font.NORMAL, TEXT), rowBg));
                    drugsTable.addCell(tableBodyCell(durationAndQuantity(item), new Font(Font.HELVETICA, 9.2f, Font.NORMAL, TEXT), rowBg));
                    drugsTable.addCell(tableBodyCell(valueOrDash(item.instructions()), new Font(Font.HELVETICA, 9.2f, Font.ITALIC, TEXT), rowBg));
                }
            }

            document.add(drugsTable);

            // 5. Signature area
            PdfPTable signatureTable = new PdfPTable(2);
            signatureTable.setWidthPercentage(100);
            signatureTable.setWidths(new float[]{60, 40});

            PdfPCell leftSig = new PdfPCell();
            leftSig.setBorder(Rectangle.NO_BORDER);
            signatureTable.addCell(leftSig);

            PdfPCell rightSig = new PdfPCell();
            rightSig.setBorder(Rectangle.NO_BORDER);
            rightSig.setPaddingTop(6);
            rightSig.setPaddingRight(10);
            
            Paragraph sigPara = new Paragraph();
            sigPara.setAlignment(Element.ALIGN_RIGHT);
            sigPara.setLeading(12f);
            sigPara.add(new Chunk("Signature & Cachet\n", new Font(Font.HELVETICA, 9.2f, Font.BOLD, DEEP_HEALTH_BLUE)));
            sigPara.add(new Chunk("_____________________\n", new Font(Font.HELVETICA, 9, Font.NORMAL, DEEP_HEALTH_BLUE)));
            
            rightSig.addElement(sigPara);
            signatureTable.addCell(rightSig);

            document.add(signatureTable);

            document.close();
        } catch (Exception e) {
            throw new RuntimeException("Erreur de génération de l'ordonnance en PDF", e);
        }

        return out.toByteArray();
    }

    private static PdfPCell tableHeaderCell(String value) {
        PdfPCell cell = new PdfPCell(new Phrase(value, new Font(Font.HELVETICA, 9.5f, Font.BOLD, Color.WHITE)));
        cell.setBackgroundColor(DEEP_HEALTH_BLUE);
        cell.setBorderColor(DEEP_HEALTH_BLUE);
        cell.setPadding(6);
        return cell;
    }

    private static PdfPCell tableBodyCell(String value, Font font, Color backgroundColor) {
        return tableBodyCell(new Phrase(valueOrDash(value), font), backgroundColor);
    }

    private static PdfPCell tableBodyCell(Phrase phrase, Color backgroundColor) {
        PdfPCell cell = new PdfPCell(phrase);
        cell.setPaddingTop(7);
        cell.setPaddingBottom(7);
        cell.setPaddingLeft(7);
        cell.setPaddingRight(7);
        cell.setLeading(0, 1.22f);
        cell.setBorderColor(SOFT_BORDER);
        cell.setBackgroundColor(backgroundColor);
        return cell;
    }

    private static String posology(PrescriptionItemEntity item) {
        StringBuilder value = new StringBuilder();
        appendLine(value, "Dosage", item.dosage());
        appendLine(value, "Fréquence", item.frequency());
        return value.isEmpty() ? "-" : value.toString();
    }

    private static String durationAndQuantity(PrescriptionItemEntity item) {
        StringBuilder value = new StringBuilder();
        appendLine(value, "Durée", item.duration());
        if (item.quantity() != null) {
            appendLine(value, "Qté", item.quantity() + " boîte(s)");
        }
        return value.isEmpty() ? "-" : value.toString();
    }

    private static void appendLine(StringBuilder target, String label, String value) {
        if (value == null || value.isBlank()) {
            return;
        }
        if (!target.isEmpty()) {
            target.append('\n');
        }
        target.append(label).append(" : ").append(value.trim());
    }

    private static String valueOrDash(String value) {
        return value == null || value.isBlank() ? "-" : value.trim();
    }

    // --- Private Static Events & Helpers for Drawing ---

    private static class MedicalCrossCellEvent implements PdfPCellEvent {
        @Override
        public void cellLayout(PdfPCell cell, Rectangle position, PdfContentByte[] canvases) {
            PdfContentByte cb = canvases[PdfPTable.BACKGROUNDCANVAS];
            cb.saveState();
            cb.setColorStroke(MEDICAL_GREEN);
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
            cb.setColorStroke(MEDICAL_GREEN);
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
            cb.setColorFill(LIGHT_CARD);
            cb.setColorStroke(SOFT_BORDER);
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
            cb.setColorStroke(MEDICAL_GREEN);
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
