
using Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Models;
using iText.Kernel.Pdf;
using iText.Layout;
using iText.Layout.Element;
using iText.Layout.Properties;
using System.IO;
using System.Threading.Tasks;

namespace Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Services
{
    public class PdfGeneratorService
    {
        // ✅ Simple writer creation – no SmartMode, no crypto dependencies
        private PdfWriter CreateWriter(MemoryStream ms)
        {
            var writer = new PdfWriter(ms);
            return writer;
        }

        // ------------------- Views Per Post -------------------
        public async Task<byte[]> GenerateViewPerPostPdf(ViewPerPostResponse data)
        {
            using var ms = new MemoryStream();
            using var writer = CreateWriter(ms);
            using var pdf = new PdfDocument(writer);
            var document = new Document(pdf);

            document.Add(new Paragraph($"View Per Post Report for Business ID: {data.businessID}").SetFontSize(18));
            document.Add(new Paragraph($"Date Range: {data.StartDate} to {data.EndDate}").SetFontSize(14));

            var table = new Table(2).UseAllAvailableWidth();
            table.AddHeaderCell("Post Name");
            table.AddHeaderCell("Views");

            if (data.DataPoints != null)
            {
                foreach (var point in data.DataPoints)
                {
                    table.AddCell(point.PostName ?? "Unknown");
                    table.AddCell(point.Views.ToString());
                }
            }
            else
            {
                table.AddCell("No data available");
                table.AddCell("-");
            }

            document.Add(table);
            document.Close();
            return await Task.FromResult(ms.ToArray());
        }

        // ------------------- Visitors Per Account -------------------
        public async Task<byte[]> GenerateVisitorsPerAccountPdf(VisitorsPerAccountResponse data)
        {
            using var ms = new MemoryStream();
            using var writer = CreateWriter(ms);
            using var pdf = new PdfDocument(writer);
            var document = new Document(pdf);

            document.Add(new Paragraph($"Unique visitors by day for Business ID: {data.businessID}").SetFontSize(18));
            document.Add(new Paragraph($"Date Range: {data.StartDate} to {data.EndDate}").SetFontSize(14));

            var table = new Table(2).UseAllAvailableWidth();
            table.AddHeaderCell("Date");
            table.AddHeaderCell("Visitors");

            if (data.DataPoints != null)
            {
                foreach (var point in data.DataPoints)
                {
                    table.AddCell(point.Date ?? "");
                    table.AddCell(point.Visitors.ToString());
                }
            }
            else
            {
                table.AddCell("No data available");
                table.AddCell("-");
            }

            document.Add(table);
            document.Close();
            return await Task.FromResult(ms.ToArray());
        }

        // ------------------- Click-Through -------------------
        public async Task<byte[]> GenerateClickThroughPdf(ClickThroughResponse data)
        {
            using var ms = new MemoryStream();
            using var writer = CreateWriter(ms);
            using var pdf = new PdfDocument(writer);
            var document = new Document(pdf);

            document.Add(new Paragraph($"Click-through report for Business ID: {data.businessID}").SetFontSize(18));
            document.Add(new Paragraph($"Date Range: {data.StartDate} to {data.EndDate}").SetFontSize(14));

            var table = new Table(2).UseAllAvailableWidth();
            table.AddHeaderCell("Date");
            table.AddHeaderCell("Clicks");

            if (data.DataPoints != null)
            {
                foreach (var point in data.DataPoints)
                {
                    table.AddCell(point.Date ?? "");
                    table.AddCell(point.Visitors.ToString());
                }
            }
            else
            {
                table.AddCell("No data available");
                table.AddCell("-");
            }

            document.Add(table);
            document.Close();
            return await Task.FromResult(ms.ToArray());
        }

        // ------------------- Follows By Day -------------------
        public async Task<byte[]> GenerateFollowsByDayPdf(FollowsByDayResponse data)
        {
            using var ms = new MemoryStream();
            using var writer = CreateWriter(ms);
            using var pdf = new PdfDocument(writer);
            var document = new Document(pdf);

            document.Add(new Paragraph($"New followers by day for Business ID: {data.businessID}").SetFontSize(18));
            document.Add(new Paragraph($"Date Range: {data.StartDate} to {data.EndDate}").SetFontSize(14));

            var table = new Table(2).UseAllAvailableWidth();
            table.AddHeaderCell("Date");
            table.AddHeaderCell("New Follows");

            if (data.DataPoints != null)
            {
                foreach (var point in data.DataPoints)
                {
                    table.AddCell(point.Date ?? "");
                    table.AddCell(point.Follows.ToString());
                }
            }
            else
            {
                table.AddCell("No data available");
                table.AddCell("-");
            }

            document.Add(table);
            document.Close();
            return await Task.FromResult(ms.ToArray());
        }
    }
}