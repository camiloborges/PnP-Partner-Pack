﻿using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace OfficeDevPnP.PartnerPack.Infrastructure.TemplatesProviders
{
    /// <summary>
    /// Class that represents an item of the result from the PnPTemplatesGallery search
    /// </summary>
    public class PnPTemplatesGalleryResultItem
    {
        public Guid Id { get; set; }

        public String Title { get; set; }

        public String Abstract { get; set; }

        public String ImageUrl { get; set; }

        public String TemplatePnPUrl { get; set; }

        public String SEO { get; set; }

        public String BaseTemplate { get; set; }

        public double Rating { get; set; }

        [JsonConverter(typeof(StringEnumConverter))]
        public TargetScope Scopes { get; set; }

        [JsonConverter(typeof(StringEnumConverter))]
        public TargetPlatform Platforms { get; set; }
    }
}
