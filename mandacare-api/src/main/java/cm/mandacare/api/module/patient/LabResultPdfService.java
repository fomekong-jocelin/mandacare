package cm.mandacare.api.module.patient;

import com.lowagie.text.Chunk;
import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.Image;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPCellEvent;
import com.lowagie.text.pdf.PdfContentByte;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfPageEventHelper;
import com.lowagie.text.pdf.PdfWriter;
import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import org.springframework.stereotype.Service;

@Service
class LabResultPdfService {

    private static final Color DEEP_HEALTH_BLUE = new Color(11, 59, 96);
    private static final Color MEDICAL_GREEN = new Color(46, 125, 50);
    private static final Color TEXT = new Color(60, 60, 60);
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy")
            .withZone(ZoneId.systemDefault());
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
            .withZone(ZoneId.systemDefault());

    byte[] generatePdf(LabResultEntity labResult) {
        Document document = new Document(PageSize.A4, 40, 40, 45, 75);
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        try {
            PdfWriter writer = PdfWriter.getInstance(document, out);
            writer.setPageEvent(new FooterEvent());
            document.open();

            document.add(headerTable());
            document.add(titleTable(labResult));
            document.add(patientCard(labResult));
            document.add(resultsCard(labResult));
            document.add(signatureTable());

            document.close();
        } catch (Exception e) {
            throw new RuntimeException("Erreur de génération des résultats de laboratoire en PDF", e);
        }

        return out.toByteArray();
    }

    private PdfPTable headerTable() throws Exception {
        PdfPTable headerTable = new PdfPTable(2);
        headerTable.setWidthPercentage(100);
        headerTable.setWidths(new float[]{70, 30});
        headerTable.setSpacingAfter(15);

        PdfPCell cellLeft = new PdfPCell();
        cellLeft.setBorder(Rectangle.NO_BORDER);
        try {
            var logoUrl = getClass().getResource("/assets/brand/mandacare_logo_horizontal.png");
            if (logoUrl != null) {
                Image logo = Image.getInstance(logoUrl);
                logo.scalePercent(15f);
                cellLeft.addElement(logo);
            } else {
                addFallbackBrand(cellLeft);
            }
        } catch (Exception e) {
            addFallbackBrand(cellLeft);
        }
        headerTable.addCell(cellLeft);

        PdfPCell cellRight = new PdfPCell();
        cellRight.setBorder(Rectangle.NO_BORDER);
        cellRight.setCellEvent(new MedicalCrossCellEvent());
        headerTable.addCell(cellRight);
        return headerTable;
    }

    private void addFallbackBrand(PdfPCell cell) {
        Font brandFont = new Font(Font.HELVETICA, 20, Font.BOLD, DEEP_HEALTH_BLUE);
        Font subBrandFont = new Font(Font.HELVETICA, 10, Font.ITALIC, MEDICAL_GREEN);
        cell.addElement(new Paragraph("MandaCare", brandFont));
        cell.addElement(new Paragraph("Soigner mieux, gérer simplement.", subBrandFont));
    }

    private PdfPTable titleTable(LabResultEntity labResult) throws Exception {
        PdfPTable titleTable = new PdfPTable(2);
        titleTable.setWidthPercentage(100);
        titleTable.setWidths(new float[]{60, 40});
        titleTable.setSpacingAfter(20);

        Font titleFont = new Font(Font.HELVETICA, 22, Font.BOLD, DEEP_HEALTH_BLUE);
        PdfPCell titleCell = new PdfPCell(new Paragraph("Résultats de laboratoire", titleFont));
        titleCell.setBorder(Rectangle.NO_BORDER);
        titleCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        titleCell.setCellEvent(new GreenUnderlineCellEvent());
        titleTable.addCell(titleCell);

        Font metaLabelFont = new Font(Font.HELVETICA, 10, Font.BOLD, new Color(100, 100, 100));
        Font metaValueFont = new Font(Font.HELVETICA, 10, Font.NORMAL, new Color(50, 50, 50));

        Paragraph metaPara = new Paragraph();
        metaPara.setLeading(14f);
        metaPara.setAlignment(Element.ALIGN_RIGHT);
        metaPara.add(new Chunk("Date validation : ", metaLabelFont));
        metaPara.add(new Chunk(DATE_TIME_FORMATTER.format(labResult.createdAt()) + "\n", metaValueFont));
        metaPara.add(new Chunk("N° Résultat : ", metaLabelFont));
        metaPara.add(new Chunk(labResult.resultNumber(), metaValueFont));

        PdfPCell metaCell = new PdfPCell(metaPara);
        metaCell.setBorder(Rectangle.NO_BORDER);
        metaCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        titleTable.addCell(metaCell);

        return titleTable;
    }

    private PdfPTable patientCard(LabResultEntity labResult) throws Exception {
        PatientEntity patient = labResult.patient();
        String birthOrAge = patient.birthDate() != null
                ? patient.birthDate().toString()
                : (patient.declaredAge() != null ? patient.declaredAge() + " ans" : "-");

        PdfPTable infoCardTable = new PdfPTable(1);
        infoCardTable.setWidthPercentage(100);
        infoCardTable.setSpacingAfter(20);

        PdfPCell cardCell = new PdfPCell();
        cardCell.setPadding(12);
        cardCell.setBorder(Rectangle.NO_BORDER);
        cardCell.setCellEvent(new RoundedBorderCellEvent());

        PdfPTable innerInfo = new PdfPTable(3);
        innerInfo.setWidthPercentage(100);
        innerInfo.setWidths(new float[]{10, 45, 45});

        PdfPCell iconCell = new PdfPCell();
        iconCell.setBorder(Rectangle.NO_BORDER);
        iconCell.setCellEvent(new UserIconCellEvent());
        innerInfo.addCell(iconCell);

        PdfPCell patientDetailsCell = new PdfPCell();
        patientDetailsCell.setBorder(Rectangle.NO_BORDER);
        patientDetailsCell.addElement(keyValueParagraph(
                "Patient : ", patient.fullName(),
                "Âge / Sexe : ", birthOrAge + " / " + patient.sex(),
                "ID Patient : ", patient.patientNumber()
        ));
        innerInfo.addCell(patientDetailsCell);

        String sampleDate = labResult.sampleDate() == null ? "-" : labResult.sampleDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
        PdfPCell labDetailsCell = new PdfPCell();
        labDetailsCell.setBorder(Rectangle.NO_BORDER);
        labDetailsCell.addElement(keyValueParagraph(
                "Dossier LAB : ", valueOrDash(labResult.dossierNumber()),
                "Prélevé le : ", sampleDate,
                "Service : ", "Laboratoire"
        ));
        innerInfo.addCell(labDetailsCell);

        cardCell.addElement(innerInfo);
        infoCardTable.addCell(cardCell);
        return infoCardTable;
    }

    private Paragraph keyValueParagraph(String... parts) {
        Font labelFont = new Font(Font.HELVETICA, 10, Font.BOLD, DEEP_HEALTH_BLUE);
        Font valueFont = new Font(Font.HELVETICA, 10, Font.NORMAL, TEXT);
        Paragraph paragraph = new Paragraph();
        paragraph.setLeading(16f);
        for (int i = 0; i < parts.length; i += 2) {
            paragraph.add(new Chunk(parts[i], labelFont));
            paragraph.add(new Chunk(valueOrDash(parts[i + 1]) + "\n", valueFont));
        }
        return paragraph;
    }

    private PdfPTable resultsCard(LabResultEntity labResult) throws Exception {
        PdfPTable outer = new PdfPTable(1);
        outer.setWidthPercentage(100);
        outer.setSpacingAfter(24);

        PdfPCell cell = new PdfPCell();
        cell.setPadding(18);
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setCellEvent(new RoundedBorderCellEvent());

        Font sectionFont = new Font(Font.HELVETICA, 12, Font.BOLD, DEEP_HEALTH_BLUE);
        Font valueFont = new Font(Font.HELVETICA, 10.5f, Font.NORMAL, TEXT);
        Font statusFont = labResult.normalResults()
                ? new Font(Font.HELVETICA, 10, Font.BOLD, MEDICAL_GREEN)
                : new Font(Font.HELVETICA, 10, Font.BOLD, new Color(180, 55, 55));

        cell.addElement(new Paragraph("Type d'examen", sectionFont));
        cell.addElement(spacedParagraph(compactExamType(labResult.examType()), valueFont, 8));

        cell.addElement(new Paragraph("Statut", sectionFont));
        cell.addElement(spacedParagraph(
                labResult.normalResults() ? "Résultats normaux" : "Résultats à interpréter",
                statusFont,
                8
        ));

        cell.addElement(new Paragraph("Analyses / Résultats saisis", sectionFont));
        cell.addElement(spacedParagraph(valueOrDash(labResult.results()), valueFont, 12));

        if (labResult.observations() != null && !labResult.observations().isBlank()) {
            cell.addElement(new Paragraph("Observations du laboratoire", sectionFont));
            cell.addElement(spacedParagraph(labResult.observations(), valueFont, 0));
        }

        outer.addCell(cell);
        return outer;
    }

    private Paragraph spacedParagraph(String text, Font font, float spacingAfter) {
        Paragraph paragraph = new Paragraph(text, font);
        paragraph.setLeading(15f);
        paragraph.setSpacingAfter(spacingAfter);
        return paragraph;
    }

    private PdfPTable signatureTable() throws Exception {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{50, 50});

        PdfPCell left = new PdfPCell(new Phrase(""));
        left.setBorder(Rectangle.NO_BORDER);
        table.addCell(left);

        Paragraph signature = new Paragraph();
        signature.setAlignment(Element.ALIGN_RIGHT);
        signature.setLeading(14f);
        signature.add(new Chunk("Responsable laboratoire\n\n\n\n", new Font(Font.HELVETICA, 10, Font.BOLD, DEEP_HEALTH_BLUE)));
        signature.add(new Chunk("_____________________\n", new Font(Font.HELVETICA, 10, Font.NORMAL, DEEP_HEALTH_BLUE)));
        signature.add(new Chunk("Signature & Cachet", new Font(Font.HELVETICA, 8, Font.ITALIC, new Color(100, 100, 100))));

        PdfPCell right = new PdfPCell(signature);
        right.setBorder(Rectangle.NO_BORDER);
        right.setPaddingRight(10);
        table.addCell(right);
        return table;
    }

    private static String compactExamType(String value) {
        if (value == null || value.isBlank()) {
            return "-";
        }
        int separator = value.indexOf(" - ");
        return separator > 0 ? value.substring(0, separator).trim() : value.trim();
    }

    private static String valueOrDash(String value) {
        return value == null || value.isBlank() ? "-" : value.trim();
    }

    private static class FooterEvent extends PdfPageEventHelper {
        @Override
        public void onEndPage(PdfWriter writer, Document document) {
            PdfContentByte cb = writer.getDirectContent();
            cb.saveState();
            float width = document.getPageSize().getWidth();
            cb.setColorFill(DEEP_HEALTH_BLUE);
            cb.moveTo(0, 0);
            cb.lineTo(0, 20);
            cb.curveTo(width * 0.25f, 32, width * 0.5f, 15, width * 0.75f, 0);
            cb.lineTo(0, 0);
            cb.fill();
            cb.setColorFill(MEDICAL_GREEN);
            cb.moveTo(width * 0.45f, 0);
            cb.curveTo(width * 0.6f, 12, width * 0.8f, 25, width, 35);
            cb.lineTo(width, 0);
            cb.lineTo(width * 0.45f, 0);
            cb.fill();
            cb.restoreState();
        }
    }

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
            float cy = position.getTop() - height / 2 - 10f;
            float arm = 10f;
            cb.moveTo(cx - arm / 2, cy + height / 2);
            cb.lineTo(cx + arm / 2, cy + height / 2);
            cb.lineTo(cx + arm / 2, cy + arm / 2);
            cb.lineTo(cx + width / 2, cy + arm / 2);
            cb.lineTo(cx + width / 2, cy - arm / 2);
            cb.lineTo(cx + arm / 2, cy - arm / 2);
            cb.lineTo(cx + arm / 2, cy - height / 2);
            cb.lineTo(cx - arm / 2, cy - height / 2);
            cb.lineTo(cx - arm / 2, cy - arm / 2);
            cb.lineTo(cx - width / 2, cy - arm / 2);
            cb.lineTo(cx - width / 2, cy + arm / 2);
            cb.lineTo(cx - arm / 2, cy + arm / 2);
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
            cb.lineTo(position.getLeft() + 35, position.getBottom() - 4);
            cb.stroke();
            cb.restoreState();
        }
    }

    private static class RoundedBorderCellEvent implements PdfPCellEvent {
        @Override
        public void cellLayout(PdfPCell cell, Rectangle position, PdfContentByte[] canvases) {
            PdfContentByte cb = canvases[PdfPTable.BACKGROUNDCANVAS];
            cb.saveState();
            cb.setColorFill(new Color(248, 250, 252));
            cb.setColorStroke(new Color(225, 230, 235));
            cb.setLineWidth(1f);
            cb.roundRectangle(position.getLeft(), position.getBottom(), position.getWidth(), position.getHeight(), 10f);
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
            cb.circle(cx, cy + 8, 5.5f);
            cb.stroke();
            cb.moveTo(cx - 9, cy - 8);
            cb.curveTo(cx - 9, cy, cx + 9, cy, cx + 9, cy - 8);
            cb.stroke();
            cb.restoreState();
        }
    }
}
