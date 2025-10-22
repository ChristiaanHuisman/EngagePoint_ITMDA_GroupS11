
using Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Models;
using iText.Kernel.Pdf;
using iText.Layout;
using iText.Layout.Element;

namespace Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Services
{
    public class PdfGeneratorService
    {
        public async Task<byte[]> GenerateViewPerPostPdf(ViewPerPostResponse data)
        {
            using var ms = new MemoryStream();
            using var writer = new PdfWriter(ms);
            using var pdf = new PdfDocument(writer);
            var document = new Document(pdf);

            document.Add(new Paragraph($"View Per Post Report for Business ID: {data.businessID}")).SetFontSize(18);//Pdf Title

            document.Add(new Paragraph($"Date Range: {data.StartDate} to {data.EndDate}")).SetFontSize(14);//Date Range


            var table = new Table(2).UseAllAvailableWidth();  //initial setup of the table
            table.AddHeaderCell("Post Name");
            table.AddHeaderCell("Views");

            foreach (var point in data.DataPoints)  //adding data to the table
            {
                table.AddCell(point.PostName);
                table.AddCell(point.Views.ToString());
            }

            document.Add(table);
            document.Close();

            return ms.ToArray();
        }


        public async Task<byte[]> GenerateVisitorsPerAccountPdf(VisitorsPerAccountResponse data)
        {
            using var ms = new MemoryStream();
            using var writer = new PdfWriter(ms);
            using var pdf = new PdfDocument(writer);
            var document = new Document(pdf);

            document.Add(new Paragraph($"Unique visitors by day for Business ID: {data.businessID}")).SetFontSize(18);//Pdf Title

            document.Add(new Paragraph($"Date Range: {data.StartDate} to {data.EndDate}")).SetFontSize(14);//Date Range


            var table = new Table(2).UseAllAvailableWidth();  //initial setup of the table
            table.AddHeaderCell("Date");
            table.AddHeaderCell("Visitors");

            foreach (var point in data.DataPoints)  //adding data to the table
            {
                table.AddCell(point.Date);
                table.AddCell(point.Visitors.ToString());
            }

            document.Add(table);
            document.Close();

            return ms.ToArray();
        }

        public async Task<byte[]> GenerateClickThroughPdf(ClickThroughResponse data)
        {
            using var ms = new MemoryStream();
            using var writer = new PdfWriter(ms);
            using var pdf = new PdfDocument(writer);
            var document = new Document(pdf);

            document.Add(new Paragraph($"Click through per day for business ID: {data.businessID}")).SetFontSize(18);//Pdf Title

            document.Add(new Paragraph($"Date Range: {data.StartDate} to {data.EndDate}")).SetFontSize(14);//Date Range


            var table = new Table(2).UseAllAvailableWidth();  //initial setup of the table
            table.AddHeaderCell("Date");
            table.AddHeaderCell("Visitors");

            foreach (var point in data.DataPoints)  //adding data to the table
            {
                table.AddCell(point.Date);
                table.AddCell(point.Visitors.ToString());
            }

            document.Add(table);
            document.Close();

            return ms.ToArray();
        }


        public async Task<byte[]> GenerateFollowsByDayPdf(FollowsByDayResponse data)
        {
            using var ms = new MemoryStream();
            using var writer = new PdfWriter(ms);
            using var pdf = new PdfDocument(writer);
            var document = new Document(pdf);

            document.Add(new Paragraph($"New followers by day for Business ID: {data.businessID}")).SetFontSize(18);//Pdf Title

            document.Add(new Paragraph($"Date Range: {data.StartDate} to {data.EndDate}")).SetFontSize(14);//Date Range


            var table = new Table(2).UseAllAvailableWidth();  //initial setup of the table
            table.AddHeaderCell("Date");
            table.AddHeaderCell("New Follows");

            foreach (var point in data.DataPoints)  //adding data to the table
            {
                table.AddCell(point.Date);
                table.AddCell(point.Follows.ToString());
            }

            document.Add(table);
            document.Close();

            return ms.ToArray();
        }
    }
}