package cm.mandacare.api.module.patient;

import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.pdf.*;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

@Service
class InvoicePdfService {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
            .withZone(ZoneId.systemDefault());

    public byte[] generatePdf(InvoiceEntity invoice) {
        // Margins: Left 40, Right 40, Top 45, Bottom 75 (gives safe space for footer background curves)
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

            try {
                var logoUrl = getClass().getResource("/assets/brand/mandacare_logo_horizontal.png");
                if (logoUrl != null) {
                    Image logo = Image.getInstance(logoUrl);
                    logo.scalePercent(15f);
                    cellLeft.addElement(logo);
                } else {
                    Font brandFont = new Font(Font.HELVETICA, 20, Font.BOLD, new Color(11, 59, 96));
                    Font subBrandFont = new Font(Font.HELVETICA, 10, Font.ITALIC, new Color(46, 125, 50));
                    cellLeft.addElement(new Paragraph("MandaCare", brandFont));
                    cellLeft.addElement(new Paragraph("Soigner mieux, gérer simplement.", subBrandFont));
                }
            } catch (Exception e) {
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

            // 2. Title Section ("Reçu de paiement" or "Facture")
            PdfPTable titleTable = new PdfPTable(2);
            titleTable.setWidthPercentage(100);
            titleTable.setWidths(new float[]{60, 40});
            titleTable.setSpacingAfter(20);

            // Left side: Title based on paid status
            String documentTitle = "PAID".equalsIgnoreCase(invoice.status()) ? "Reçu de paiement" : "Facture de soins";
            Font titleFont = new Font(Font.HELVETICA, 22, Font.BOLD, new Color(11, 59, 96));
            PdfPCell titleCell = new PdfPCell(new Paragraph(documentTitle, titleFont));
            titleCell.setBorder(Rectangle.NO_BORDER);
            titleCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            titleCell.setCellEvent(new GreenUnderlineCellEvent());
            titleTable.addCell(titleCell);

            // Right side: Date and invoice number
            Font metaLabelFont = new Font(Font.HELVETICA, 10, Font.BOLD, new Color(100, 100, 100));
            Font metaValueFont = new Font(Font.HELVETICA, 10, Font.NORMAL, new Color(50, 50, 50));

            PdfPCell metaCell = new PdfPCell();
            metaCell.setBorder(Rectangle.NO_BORDER);
            metaCell.setVerticalAlignment(Element.ALIGN_MIDDLE);

            Paragraph metaPara = new Paragraph();
            metaPara.setLeading(14f);
            metaPara.setAlignment(Element.ALIGN_RIGHT);
            metaPara.add(new Chunk("Date : ", metaLabelFont));
            metaPara.add(new Chunk(DATE_FORMATTER.format(invoice.createdAt()) + "\n", metaValueFont));
            metaPara.add(new Chunk("N° Facture : ", metaLabelFont));
            metaPara.add(new Chunk(invoice.invoiceNumber(), metaValueFont));

            metaCell.addElement(metaPara);
            titleTable.addCell(metaCell);

            document.add(titleTable);

            // 3. Patient & Cashier Info Card (Rounded Light Gray Card)
            PatientEntity patient = invoice.patient();
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

            // Column 3: Cashier Info
            PdfPCell cashierDetailsCell = new PdfPCell();
            cashierDetailsCell.setBorder(Rectangle.NO_BORDER);
            Paragraph cDetails = new Paragraph();
            cDetails.setLeading(16f);
            cDetails.add(new Chunk("Service : ", infoHeaderFont));
            cDetails.add(new Chunk("Caisse MandaCare\n", infoValFont));
            cDetails.add(new Chunk("Statut Facture : ", infoHeaderFont));

            String statusLabel = "PAID".equalsIgnoreCase(invoice.status()) ? "PAYÉE" : "PARTIELLEMENT PAYÉE";
            Color statusColor = "PAID".equalsIgnoreCase(invoice.status()) ? new Color(46, 125, 50) : new Color(245, 124, 0);
            cDetails.add(new Chunk(statusLabel + "\n", new Font(Font.HELVETICA, 10, Font.BOLD, statusColor)));
            cDetails.add(new Chunk("Reste à payer : ", infoHeaderFont));
            cDetails.add(new Chunk(formatCurrency(invoice.remainingAmount()) + "\n", infoValFont));

            cashierDetailsCell.addElement(cDetails);
            innerInfo.addCell(cashierDetailsCell);

            cardCell.addElement(innerInfo);
            infoCardTable.addCell(cardCell);
            document.add(infoCardTable);

            // 4. Detailed Items Table
            Font tableHeaderFont = new Font(Font.HELVETICA, 10, Font.BOLD, Color.WHITE);
            Font tableBodyFont = new Font(Font.HELVETICA, 9.5f, Font.NORMAL, new Color(50, 50, 50));
            Font tableBodyBoldFont = new Font(Font.HELVETICA, 9.5f, Font.BOLD, new Color(11, 59, 96));

            PdfPTable itemsTable = new PdfPTable(5);
            itemsTable.setWidthPercentage(100);
            itemsTable.setWidths(new float[]{40, 15, 15, 12, 18});
            itemsTable.setHeaderRows(1);
            itemsTable.setSplitRows(true);
            itemsTable.setSplitLate(false);
            itemsTable.setSpacingAfter(20);

            // Table Headers
            String[] headers = {"Désignation", "Type", "Prix Unit.", "Qté", "Montant"};
            for (String header : headers) {
                PdfPCell hCell = new PdfPCell(new Paragraph(header, tableHeaderFont));
                hCell.setBackgroundColor(new Color(11, 59, 96)); // Deep Health Blue
                hCell.setBorder(Rectangle.NO_BORDER);
                hCell.setPadding(8);
                if ("Désignation".equals(header)) {
                    hCell.setHorizontalAlignment(Element.ALIGN_LEFT);
                } else if ("Qté".equals(header) || "Type".equals(header)) {
                    hCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                } else {
                    hCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
                }
                itemsTable.addCell(hCell);
            }

            // Populate Table rows
            boolean alternate = false;
            for (InvoiceItemEntity item : invoice.items()) {
                Color rowBg = alternate ? new Color(245, 247, 250) : Color.WHITE;
                alternate = !alternate;

                // 1. Description
                PdfPCell descCell = new PdfPCell(new Paragraph(item.label(), tableBodyBoldFont));
                descCell.setBackgroundColor(rowBg);
                descCell.setBorder(Rectangle.NO_BORDER);
                descCell.setPadding(8);
                descCell.setCellEvent(new BottomLineCellEvent());
                itemsTable.addCell(descCell);

                // 2. Type
                String typeLabel = "EXAM".equalsIgnoreCase(item.type()) ? "Examen" : "Prestation";
                PdfPCell typeCell = new PdfPCell(new Paragraph(typeLabel, tableBodyFont));
                typeCell.setBackgroundColor(rowBg);
                typeCell.setBorder(Rectangle.NO_BORDER);
                typeCell.setPadding(8);
                typeCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                typeCell.setCellEvent(new BottomLineCellEvent());
                itemsTable.addCell(typeCell);

                // 3. Unit Price
                PdfPCell priceCell = new PdfPCell(new Paragraph(formatCurrency(item.price()), tableBodyFont));
                priceCell.setBackgroundColor(rowBg);
                priceCell.setBorder(Rectangle.NO_BORDER);
                priceCell.setPadding(8);
                priceCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
                priceCell.setCellEvent(new BottomLineCellEvent());
                itemsTable.addCell(priceCell);

                // 4. Quantity
                PdfPCell qtyCell = new PdfPCell(new Paragraph(String.valueOf(item.quantity()), tableBodyFont));
                qtyCell.setBackgroundColor(rowBg);
                qtyCell.setBorder(Rectangle.NO_BORDER);
                qtyCell.setPadding(8);
                qtyCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                qtyCell.setCellEvent(new BottomLineCellEvent());
                itemsTable.addCell(qtyCell);

                // 5. Line Total
                BigDecimal lineTotal = item.price().multiply(BigDecimal.valueOf(item.quantity()));
                PdfPCell totalCell = new PdfPCell(new Paragraph(formatCurrency(lineTotal), tableBodyBoldFont));
                totalCell.setBackgroundColor(rowBg);
                totalCell.setBorder(Rectangle.NO_BORDER);
                totalCell.setPadding(8);
                totalCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
                totalCell.setCellEvent(new BottomLineCellEvent());
                itemsTable.addCell(totalCell);
            }

            document.add(itemsTable);

            // 5. Totals Block and Signature Area side-by-side
            PdfPTable bottomTable = new PdfPTable(2);
            bottomTable.setWidthPercentage(100);
            bottomTable.setWidths(new float[]{50, 50});
            bottomTable.setSpacingAfter(20);

            // Left Side: Totals Summary
            PdfPCell leftCell = new PdfPCell();
            leftCell.setBorder(Rectangle.NO_BORDER);

            PdfPTable totalsTable = new PdfPTable(2);
            totalsTable.setWidthPercentage(90);
            totalsTable.setWidths(new float[]{60, 40});
            totalsTable.setHorizontalAlignment(Element.ALIGN_LEFT);

            Font summaryLabelFont = new Font(Font.HELVETICA, 10, Font.NORMAL, new Color(80, 80, 80));
            Font summaryValueFont = new Font(Font.HELVETICA, 10, Font.BOLD, new Color(50, 50, 50));
            Font netLabelFontBold = new Font(Font.HELVETICA, 11, Font.BOLD, new Color(11, 59, 96));
            Font netValueFontBold = new Font(Font.HELVETICA, 11, Font.BOLD, new Color(46, 125, 50));

            // Total Brut
            totalsTable.addCell(createSummaryLabelCell("Total Brut :", summaryLabelFont));
            totalsTable.addCell(createSummaryValueCell(formatCurrency(invoice.totalAmount()), summaryValueFont));

            // Remise
            totalsTable.addCell(createSummaryLabelCell("Remise :", summaryLabelFont));
            totalsTable.addCell(createSummaryValueCell(formatCurrency(invoice.discount()), summaryValueFont));

            // Net à payer
            totalsTable.addCell(createSummaryLabelCell("Net à payer :", netLabelFontBold));
            totalsTable.addCell(createSummaryValueCell(formatCurrency(invoice.netAmount()), netValueFontBold));

            // Montant Versé
            totalsTable.addCell(createSummaryLabelCell("Montant Versé :", summaryLabelFont));
            totalsTable.addCell(createSummaryValueCell(formatCurrency(invoice.paidAmount()), summaryValueFont));

            // Reste à payer
            totalsTable.addCell(createSummaryLabelCell("Reste à payer :", summaryLabelFont));
            totalsTable.addCell(createSummaryValueCell(formatCurrency(invoice.remainingAmount()), summaryValueFont));

            leftCell.addElement(totalsTable);
            bottomTable.addCell(leftCell);

            // Right Side: Signature Area
            PdfPCell rightCell = new PdfPCell();
            rightCell.setBorder(Rectangle.NO_BORDER);
            rightCell.setPaddingTop(15);
            rightCell.setPaddingRight(10);

            Paragraph sigPara = new Paragraph();
            sigPara.setAlignment(Element.ALIGN_RIGHT);
            sigPara.setLeading(14f);
            sigPara.add(new Chunk("Le Caissier\n\n\n\n", new Font(Font.HELVETICA, 10, Font.BOLD, new Color(11, 59, 96))));
            sigPara.add(new Chunk("_____________________\n", new Font(Font.HELVETICA, 10, Font.NORMAL, new Color(11, 59, 96))));
            sigPara.add(new Chunk("Signature & Cachet", new Font(Font.HELVETICA, 8, Font.ITALIC, new Color(100, 100, 100))));

            rightCell.addElement(sigPara);
            bottomTable.addCell(rightCell);

            document.add(bottomTable);

            document.close();
        } catch (Exception e) {
            throw new RuntimeException("Erreur de génération de la facture en PDF", e);
        }

        return out.toByteArray();
    }

    private static PdfPCell createSummaryLabelCell(String text, Font font) {
        PdfPCell cell = new PdfPCell(new Paragraph(text, font));
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setPadding(4);
        cell.setHorizontalAlignment(Element.ALIGN_LEFT);
        return cell;
    }

    private static PdfPCell createSummaryValueCell(String text, Font font) {
        PdfPCell cell = new PdfPCell(new Paragraph(text, font));
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setPadding(4);
        cell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        return cell;
    }

    private static String formatCurrency(BigDecimal amount) {
        if (amount == null) {
            return "0 FCFA";
        }
        return String.format("%,.0f FCFA", amount.doubleValue());
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

            cb.circle(cx, cy + 8, 5.5f);
            cb.stroke();

            cb.moveTo(cx - 9, cy - 8);
            cb.curveTo(cx - 9, cy, cx + 9, cy, cx + 9, cy - 8);
            cb.stroke();

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
