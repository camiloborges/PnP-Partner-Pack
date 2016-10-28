using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using OfficeDevPnP.PartnerPack.Infrastructure;

namespace OfficeDevPnP.PartnerPack.ScheduledJob
{
    class Program
    {
        static void Main()
        {
            System.Threading.Thread.Sleep(20 * 1000);
#if DEBUG
//            System.Threading.Thread.Sleep(45 * 1000);
#endif
            var job = new PnPPartnerPackProvisioningJob();
            job.UseThreading = false;

            job.AddSite(PnPPartnerPackSettings.InfrastructureSiteUrl);

            job.UseAzureADAppOnlyAuthentication(
                PnPPartnerPackSettings.ClientId,
                PnPPartnerPackSettings.Tenant,
                PnPPartnerPackSettings.AppOnlyCertificate);

            job.Run();

#if DEBUGLOCAL
            Console.ReadLine();
#endif
        }
    }
}
