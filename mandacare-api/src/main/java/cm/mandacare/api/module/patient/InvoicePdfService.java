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

    private static final Color DEEP_HEALTH_BLUE = new Color(11, 59, 96);
    private static final Color MEDICAL_GREEN = new Color(46, 125, 50);
    private static final Color TEXT = new Color(60, 60, 60);
    private static final Color MUTED_TEXT = new Color(105, 112, 122);
    private static final Color LIGHT_CARD = new Color(248, 250, 252);
    private static final Color SOFT_BORDER = new Color(225, 230, 235);
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
            .withZone(ZoneId.systemDefault());

    public byte[] generatePdf(InvoiceEntity invoice) {
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

            try {
                var logoUrl = getClass().getResource("/assets/brand/mandacare_logo_horizontal.png");
                if (logoUrl != null) {
                    Image logo = Image.getInstance(logoUrl);
                    logo.scalePercent(13.5f);
                    cellLeft.addElement(logo);
                } else {
                    Font brandFont = new Font(Font.HELVETICA, 20, Font.BOLD, DEEP_HEALTH_BLUE);
                    Font subBrandFont = new Font(Font.HELVETICA, 10, Font.ITALIC, MEDICAL_GREEN);
                    cellLeft.addElement(new Paragraph("MandaCare", brandFont));
                    cellLeft.addElement(new Paragraph("Soigner mieux, gérer simplement.", subBrandFont));
                }
            } catch (Exception e) {
                Font brandFont = new Font(Font.HELVETICA, 20, Font.BOLD, DEEP_HEALTH_BLUE);
                Font subBrandFont = new Font(Font.HELVETICA, 10, Font.ITALIC, MEDICAL_GREEN);
                cellLeft.addElement(new Paragraph("MandaCare", brandFont));
                cellLeft.addElement(new Paragraph("Soigner mieux, gérer simplement.", subBrandFont));
            }
            headerTable.addCell(cellLeft);

            PdfPCell cellRight = new PdfPCell();
            cellRight.setBorder(Rectangle.NO_BORDER);
            cellRight.setCellEvent(new WalletCellEvent());
            headerTable.addCell(cellRight);

            document.add(headerTable);

            // 2. Title Section ("Reçu de paiement" or "Facture")
            PdfPTable titleTable = new PdfPTable(2);
            titleTable.setWidthPercentage(100);
            titleTable.setWidths(new float[]{60, 40});
            titleTable.setSpacingAfter(14);

            // Left side: Title based on paid status
            String documentTitle = "PAID".equalsIgnoreCase(invoice.status()) ? "Reçu de paiement" : "Facture de soins";
            Font titleFont = new Font(Font.HELVETICA, 20, Font.BOLD, DEEP_HEALTH_BLUE);
            PdfPCell titleCell = new PdfPCell(new Paragraph(documentTitle, titleFont));
            titleCell.setBorder(Rectangle.NO_BORDER);
            titleCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
            titleCell.setCellEvent(new GreenUnderlineCellEvent());
            titleTable.addCell(titleCell);

            // Right side: Date and invoice number
            Font metaLabelFont = new Font(Font.HELVETICA, 9, Font.BOLD, MUTED_TEXT);
            Font metaValueFont = new Font(Font.HELVETICA, 9, Font.NORMAL, TEXT);

            PdfPCell metaCell = new PdfPCell();
            metaCell.setBorder(Rectangle.NO_BORDER);
            metaCell.setVerticalAlignment(Element.ALIGN_MIDDLE);

            Paragraph metaPara = new Paragraph();
            metaPara.setLeading(12.5f);
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

            // Column 3: Cashier Info
            PdfPCell cashierDetailsCell = new PdfPCell();
            cashierDetailsCell.setBorder(Rectangle.NO_BORDER);
            Paragraph cDetails = new Paragraph();
            cDetails.setLeading(14f);
            cDetails.add(new Chunk("Service : ", infoHeaderFont));
            cDetails.add(new Chunk("Caisse MandaCare\n", infoValFont));
            cDetails.add(new Chunk("Statut Facture : ", infoHeaderFont));

            String statusLabel = "PAID".equalsIgnoreCase(invoice.status()) ? "PAYÉE" : "PARTIELLEMENT PAYÉE";
            Color statusColor = "PAID".equalsIgnoreCase(invoice.status()) ? MEDICAL_GREEN : new Color(245, 124, 0);
            cDetails.add(new Chunk(statusLabel + "\n", new Font(Font.HELVETICA, 10, Font.BOLD, statusColor)));
            cDetails.add(new Chunk("Reste à payer : ", infoHeaderFont));
            cDetails.add(new Chunk(formatCurrency(invoice.remainingAmount()) + "\n", infoValFont));

            cashierDetailsCell.addElement(cDetails);
            innerInfo.addCell(cashierDetailsCell);

            cardCell.addElement(innerInfo);
            infoCardTable.addCell(cardCell);
            document.add(infoCardTable);

            // 4. Detailed Items Table
            Font tableHeaderFont = new Font(Font.HELVETICA, 9.5f, Font.BOLD, Color.WHITE);
            Font tableBodyFont = new Font(Font.HELVETICA, 9.2f, Font.NORMAL, TEXT);
            Font tableBodyBoldFont = new Font(Font.HELVETICA, 9.2f, Font.BOLD, DEEP_HEALTH_BLUE);

            PdfPTable itemsTable = new PdfPTable(5);
            itemsTable.setWidthPercentage(100);
            itemsTable.setWidths(new float[]{40, 15, 15, 12, 18});
            itemsTable.setHeaderRows(1);
            itemsTable.setSplitRows(true);
            itemsTable.setSplitLate(false);
            itemsTable.setSpacingAfter(14);

            // Table Headers
            String[] headers = {"Désignation", "Type", "Prix Unit.", "Qté", "Montant"};
            for (String header : headers) {
                PdfPCell hCell = new PdfPCell(new Paragraph(header, tableHeaderFont));
                hCell.setBackgroundColor(DEEP_HEALTH_BLUE);
                hCell.setBorderColor(DEEP_HEALTH_BLUE);
                hCell.setPadding(6);
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
                Color rowBg = alternate ? LIGHT_CARD : Color.WHITE;
                alternate = !alternate;

                // 1. Description
                PdfPCell descCell = new PdfPCell(new Paragraph(item.label(), tableBodyBoldFont));
                descCell.setBackgroundColor(rowBg);
                descCell.setBorder(Rectangle.NO_BORDER);
                descCell.setPadding(7);
                descCell.setCellEvent(new BottomLineCellEvent());
                itemsTable.addCell(descCell);

                // 2. Type
                String typeLabel = "EXAM".equalsIgnoreCase(item.type()) ? "Examen" : "Prestation";
                PdfPCell typeCell = new PdfPCell(new Paragraph(typeLabel, tableBodyFont));
                typeCell.setBackgroundColor(rowBg);
                typeCell.setBorder(Rectangle.NO_BORDER);
                typeCell.setPadding(7);
                typeCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                typeCell.setCellEvent(new BottomLineCellEvent());
                itemsTable.addCell(typeCell);

                // 3. Unit Price
                PdfPCell priceCell = new PdfPCell(new Paragraph(formatCurrency(item.price()), tableBodyFont));
                priceCell.setBackgroundColor(rowBg);
                priceCell.setBorder(Rectangle.NO_BORDER);
                priceCell.setPadding(7);
                priceCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
                priceCell.setCellEvent(new BottomLineCellEvent());
                itemsTable.addCell(priceCell);

                // 4. Quantity
                PdfPCell qtyCell = new PdfPCell(new Paragraph(String.valueOf(item.quantity()), tableBodyFont));
                qtyCell.setBackgroundColor(rowBg);
                qtyCell.setBorder(Rectangle.NO_BORDER);
                qtyCell.setPadding(7);
                qtyCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                qtyCell.setCellEvent(new BottomLineCellEvent());
                itemsTable.addCell(qtyCell);

                // 5. Line Total
                BigDecimal lineTotal = item.price().multiply(BigDecimal.valueOf(item.quantity()));
                PdfPCell totalCell = new PdfPCell(new Paragraph(formatCurrency(lineTotal), tableBodyBoldFont));
                totalCell.setBackgroundColor(rowBg);
                totalCell.setBorder(Rectangle.NO_BORDER);
                totalCell.setPadding(7);
                totalCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
                totalCell.setCellEvent(new BottomLineCellEvent());
                itemsTable.addCell(totalCell);
            }

            document.add(itemsTable);

            // 5. Totals Block and Signature Area side-by-side
            PdfPTable bottomTable = new PdfPTable(2);
            bottomTable.setWidthPercentage(100);
            bottomTable.setWidths(new float[]{50, 50});
            bottomTable.setSpacingAfter(12);

            // Left Side: Totals Summary
            PdfPCell leftCell = new PdfPCell();
            leftCell.setBorder(Rectangle.NO_BORDER);

            PdfPTable totalsTable = new PdfPTable(2);
            totalsTable.setWidthPercentage(90);
            totalsTable.setWidths(new float[]{60, 40});
            totalsTable.setHorizontalAlignment(Element.ALIGN_LEFT);

            Font summaryLabelFont = new Font(Font.HELVETICA, 9.5f, Font.NORMAL, MUTED_TEXT);
            Font summaryValueFont = new Font(Font.HELVETICA, 9.5f, Font.NORMAL, TEXT);
            Font netLabelFontBold = new Font(Font.HELVETICA, 10.5f, Font.BOLD, DEEP_HEALTH_BLUE);
            Font netValueFontBold = new Font(Font.HELVETICA, 10.5f, Font.BOLD, MEDICAL_GREEN);

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
            rightCell.setPaddingTop(6);
            rightCell.setPaddingRight(10);

            Paragraph sigPara = new Paragraph();
            sigPara.setAlignment(Element.ALIGN_RIGHT);
            sigPara.setLeading(12f);
            sigPara.add(new Chunk("Le Caissier\n", new Font(Font.HELVETICA, 9.2f, Font.BOLD, DEEP_HEALTH_BLUE)));
            sigPara.add(new Chunk("\n_____________________\n", new Font(Font.HELVETICA, 9, Font.NORMAL, DEEP_HEALTH_BLUE)));
            sigPara.add(new Chunk("Signature & Cachet", new Font(Font.HELVETICA, 7.5f, Font.ITALIC, MUTED_TEXT)));

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

    private static class WalletCellEvent implements PdfPCellEvent {
        @Override
        public void cellLayout(PdfPCell cell, Rectangle position, PdfContentByte[] canvases) {
            PdfContentByte cb = canvases[PdfPTable.BACKGROUNDCANVAS];
            cb.saveState();
            cb.setColorStroke(MEDICAL_GREEN);
            cb.setLineWidth(1.5f);

            float x = position.getRight() - 58f;
            float y = position.getTop() - 45f;

            cb.roundRectangle(x + 8f, y + 7f, 42f, 26f, 4f);
            cb.moveTo(x + 8f, y + 25f);
            cb.lineTo(x + 23f, y + 35f);
            cb.lineTo(x + 50f, y + 35f);
            cb.lineTo(x + 50f, y + 25f);
            cb.moveTo(x + 37f, y + 19f);
            cb.circle(x + 37f, y + 19f, 2.2f);
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
            cb.setColorStroke(SOFT_BORDER);
            cb.setLineWidth(1f);
            cb.moveTo(position.getLeft(), position.getBottom());
            cb.lineTo(position.getRight(), position.getBottom());
            cb.stroke();
            cb.restoreState();
        }
    }
}
