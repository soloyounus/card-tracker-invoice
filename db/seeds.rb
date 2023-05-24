# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ apiLabel: 'Star Wars' }, { apiLabel: 'Lord of the Rings' }])
#   Character.create(apiLabel: 'Luke', movie: movies.first)

orderTypes = OrderType.create([
  {
    id: 1,
    apiLabel: "Add'l Web Page",
    apiValue: "Add'l Web Page"
  },
  {
    id: 2,
    apiLabel: "Advanced Digital Ads",
    apiValue: "Advanced Digital Ads"
  },
  {
    id: 3,
    apiLabel: "Advanced Landing Page",
    apiValue: "Advanced Landing Page"
  },
  {
    id: 4,
    apiLabel: "Barter Fee",
    apiValue: "Licensing_Fees"
  },
  {
    id: 5,
    apiLabel: "CTME / Amplify",
    apiValue: "CTME / Amplify"
  },
  {
    id: 6,
    apiLabel: "Custom Web Form",
    apiValue: "Custom Web Form"
  },
  {
    id: 7,
    apiLabel: "Digital Ads",
    apiValue: "Digital Ads"
  },
  {
    id: 8,
    apiLabel: "Directory Management",
    apiValue: "Directory Management"
  },
  {
    id: 9,
    apiLabel: "Email",
    apiValue: "Email"
  },
  {
    id: 10,
    apiLabel: "EPiC Guarantee",
    apiValue: "EPiC Guarantee"
  },
  {
    id: 11,
    apiLabel: "Facebook Ads",
    apiValue: "Facebook Ads"
  },
  {
    id: 12,
    apiLabel: "Gallery Module",
    apiValue: "Gallery Module"
  },
  {
    id: 13,
    apiLabel: "Google / Bing Ads",
    apiValue: "Google / Bing Ads"
  },
  {
    id: 14,
    apiLabel: "Google Analytics",
    apiValue: "Google Analytics"
  },
  {
    id: 15,
    apiLabel: "Intent",
    apiValue: "Intent"
  },
  {
    id: 16,
    apiLabel: "Landing Page",
    apiValue: "Landing Page"
  },
  {
    id: 17,
    apiLabel: "Lead Tracking",
    apiValue: "Lead Tracking"
  },
  {
    id: 18,
    apiLabel: "Monitoring Dashboard",
    apiValue: "Monitoring Dashboard"
  },
  {
    id: 19,
    apiLabel: "OTT Ads",
    apiValue: "OTT Ads"
  },
  {
    id: 20,
    apiLabel: "Reputation Management",
    apiValue: "Reputation Management"
  },
  {
    id: 21,
    apiLabel: "SEO",
    apiValue: "SEO"
  },
  {
    id: 22,
    apiLabel: "Setup - Digital Ads",
    apiValue: "Setup - Digital Ads"
  },
  {
    id: 23,
    apiLabel: "Setup - Email",
    apiValue: "Setup - Email"
  },
  {
    id: 24,
    apiLabel: "Setup - FB Ads",
    apiValue: "Setup - FB Ads"
  },
  {
    id: 25,
    apiLabel: "Smart Boundary / Watchlist",
    apiValue: "Smart Boundary / Watchlist"
  },
  {
    id: 26,
    apiLabel: "Smart Pixel",
    apiValue: "Smart Pixel"
  },
  {
    id: 27,
    apiLabel: "Social Posting",
    apiValue: "Social Posting"
  },
  {
    id: 28,
    apiLabel: "Social Tool",
    apiValue: "Social Tool"
  },
  {
    id: 29,
    apiLabel: "SSL Certificate",
    apiValue: "SSL Certificate"
  },
  {
    id: 30,
    apiLabel: "TrueView Ads",
    apiValue: "TrueView Ads"
  },
  {
    id: 31,
    apiLabel: "Video Display Ads",
    apiValue: "Video Display Ads"
  },
  {
    id: 32,
    apiLabel: "Waze Ads",
    apiValue: "Waze Ads"
  },
  {
    id: 33,
    apiLabel: "Website Design & Development",
    apiValue: "Setup"
  },
  {
    id: 34,
    apiLabel: "Website Hosting & Maintenance",
    apiValue: "Website Hosting & Maintenance"
  },
  {
    id: 35,
    apiLabel: "Advantage SEO",
    apiValue: "Advantage SEO"
  },
  {
    id: 36,
    apiLabel: "Advantage Social",
    apiValue: "Advantage Social"
  },
  {
    id: 37,
    apiLabel: "Advantage Web",
    apiValue: "Advantage Web"
  },
  {
    id: 38,
    apiLabel: "Rush Fee",
    apiValue: "Rush Fee"
  },
  {
    id: 39,
    apiLabel: "Guaranteed Display",
    apiValue: "Guaranteed Display"
  },
  {
    id: 40,
    apiLabel: 'Programmatic Audio',
    apiValue: 'Programmatic Audio'
  },
  {
    id: 41,
    apiLabel: 'TikTok Ads',
    apiValue: 'TikTok Ads'
  },
  {
    id: 42,
    apiLabel: 'Digital Out of Home',
    apiValue: 'Digital Out of Home'
  }
]);

columnGroups = ColumnGroup.create(
  [
    {
      "groupId": 1,
      "sort": 1,
      "label": "Account Name",
    },
    {
      "groupId": 1,
      "sort": 2,
      "label": "Billing Start Date",
    },
    {
      "groupId": 1,
      "sort": 3,
      "label": "Details",
    },
    {
      "groupId": 1,
      "sort": 4,
      "label": "Retail",
    },
    {
      "groupId": 1,
      "sort": 5,
      "label": "Wholesale",
    },
    {
      "groupId": 1,
      "sort": 0,
      "label": "Internal #",
    },
    {
      "groupId": 2,
      "sort": 1,
      "label": "Account Name",
    },
    {
      "groupId": 2,
      "sort": 2,
      "label": "Campaign Start",
    },
    {
      "groupId": 2,
      "sort": 3,
      "label": "Details",
    },
    {
      "groupId": 2,
      "sort": 4,
      "label": "Retail",
    },
    {
      "groupId": 2,
      "sort": 5,
      "label": "CPM",
    },
    {
      "groupId": 2,
      "sort": 6,
      "label": "Wholesale",
    },
    {
      "groupId": 2,
      "sort": 0,
      "label": "Internal #",
    },
    {
      "groupId": 3,
      "sort": 1,
      "label": "Account Name",
    },
    {
      "groupId": 3,
      "sort": 2,
      "label": "Campaign Start",
    },
    {
      "groupId": 3,
      "sort": 3,
      "label": "Details",
    },
    {
      "groupId": 3,
      "sort": 4,
      "label": "Retail",
    },
    {
      "groupId": 3,
      "sort": 5,
      "label": "CPM / Mgmt %",
    },
    {
      "groupId": 3,
      "sort": 6,
      "label": "Wholesale",
    },
    {
      "groupId": 3,
      "sort": 0,
      "label": "Internal #",
    },
    {
      "groupId": 5,
      "sort": 1,
      "label": "Details",
    },
    {
      "groupId": 5,
      "sort": 2,
      "label": "Campaign Start",
    },
    {
      "groupId": 5,
      "sort": 3,
      "label": "Amount",
    },
    {
      "groupId": 5,
      "sort": 0,
      "label": "Internal #",
    },
    {
      "groupId": 6,
      "sort": 1,
      "label": "Account Name",
    },
    {
      "groupId": 6,
      "sort": 2,
      "label": "Campaign\\ Start",
    },
    {
      "groupId": 6,
      "sort": 3,
      "label": "Campaign\\ End",
    },
    {
      "groupId": 6,
      "sort": 4,
      "label": "Details",
    },
    {
      "groupId": 6,
      "sort": 5,
      "label": "Retail",
    },
    {
      "groupId": 6,
      "sort": 6,
      "label": "Wholesale",
    },
    {
      "groupId": 6,
      "sort": 0,
      "label": "Internal #",
    },
    {
      "groupId": 7,
      "sort": 1,
      "label": "Account Name",
    },
    {
      "groupId": 7,
      "sort": 2,
      "label": "Campaign Start",
    },
    {
      "groupId": 7,
      "sort": 3,
      "label": "Details",
    },
    {
      "groupId": 7,
      "sort": 4,
      "label": "Retail",
    },
    {
      "groupId": 7,
      "sort": 5,
      "label": "Wholesale",
    },
    {
      "groupId": 7,
      "sort": 0,
      "label": "Internal #",
    },
    {
      "groupId": 8,
      "sort": 1,
      "label": "Account Name",
    },
    {
      "groupId": 8,
      "sort": 2,
      "label": "Details",
    },
    {
      "groupId": 8,
      "sort": 3,
      "label": "Billing\\ Interval",
    },
    {
      "groupId": 8,
      "sort": 4,
      "label": "Total",
    },
    {
      "groupId": 8,
      "sort": 0,
      "label": "Internal #",
    },
    {
      "groupId": 10,
      "sort": 1,
      "label": "Account Name",
    },
    {
      "groupId": 10,
      "sort": 2,
      "label": "Campaign Start",
    },
    {
      "groupId": 10,
      "sort": 3,
      "label": "Details",
    },
    {
      "groupId": 10,
      "sort": 4,
      "label": "Retail",
    },
    {
      "groupId": 10,
      "sort": 5,
      "label": "Mgmt %",
    },
    {
      "groupId": 10,
      "sort": 6,
      "label": "Wholesale",
    },
    {
      "groupId": 10,
      "sort": 0,
      "label": "Internal #",
    },
   ]
)

orderGroups = OrderGroup.create([
  {
    "id": 1,
    "label": "A la Carte Items",
    "column_group_id": 1
  },
  {
    "id": 2,
    "label": "Website Services",
    "column_group_id": 1
  },
  {
    "id": 3,
    "label": "Digital Ads",
    "column_group_id": 2
  },
  {
    "id": 4,
    "label": "Facebook Ads",
    "column_group_id": 3
  },
  {
    "id": 5,
    "label": "Email",
    "column_group_id": 2
  },
  {
    "id": 6,
    "label": "Smart Boundary/Pixel",
    "column_group_id": 5
  },
  {
    "id": 7,
    "label": "EPiC Guarantee",
    "column_group_id": 6
  },
  {
    "id": 8,
    "label": "Intent",
    "column_group_id": 7
  },
  {
    "id": 9,
    "label": "Barter Fee",
    "column_group_id": 8
  },
  {
    "id": 10,
    "label": "OTT Ads",
    "column_group_id": 2
  },
  {
    "id": 11,
    "label": "SEO",
    "column_group_id": 1
  },
  {
    "id": 12,
    "label": "Social Posting",
    "column_group_id": 1
  },
  {
    "id": 13,
    "label": "TrueView Ads",
    "column_group_id": 10
  },
  {
    "id": 14,
    "label": "Waze Ads",
    "column_group_id": 2
  },
  {
    "id": 15,
    "label": "Google / Bing Ads",
    "column_group_id": 10
  },
  {
    "id": 16,
    "label": "Advantage SEO",
    "column_group_id": 1
  },
  {
    "id": 17,
    "label": "Advantage Social",
    "column_group_id": 1
  },
  {
    "id": 18,
    "label": "Advantage Web",
    "column_group_id": 1
  },
  {
    "id": 19,
    "label": "Programmatic Audio",
    "column_group_id": 2
  },
  {
    "id": 20,
    "label": "TikTok Ads",
    "column_group_id": 2
  },
  {
    "id": 21,
    "label": "Digital Out of Home",
    "column_group_id": 2
  },
 ])


OrderGroupOrderType.create([
  {
    orderGroup_id: 1,
    orderType_id: 8
  },
  {
    orderGroup_id: 1,
    orderType_id: 20
  },
  {
    orderGroup_id: 1,
    orderType_id: 17
  },
  {
    orderGroup_id: 1,
    orderType_id: 14
  },
  {
    orderGroup_id: 1,
    orderType_id: 18
  },
  {
    orderGroup_id: 1,
    orderType_id: 28
  },
  {
    orderGroup_id: 1,
    orderType_id: 38
  },
  {
    orderGroup_id: 2,
    orderType_id: 33
  },
  {
    orderGroup_id: 2,
    orderType_id: 34
  },
  {
    orderGroup_id: 2,
    orderType_id: 29
  },
  {
    orderGroup_id: 2,
    orderType_id: 16
  },
  {
    orderGroup_id: 2,
    orderType_id: 3
  },
  {
    orderGroup_id: 2,
    orderType_id: 6
  },
  {
    orderGroup_id: 2,
    orderType_id: 1
  },
  {
    orderGroup_id: 2,
    orderType_id: 12
  },
  {
    orderGroup_id: 3,
    orderType_id: 2
  },
  {
    orderGroup_id: 3,
    orderType_id: 7
  },
  {
    orderGroup_id: 3,
    orderType_id: 22
  },
  {
    orderGroup_id: 3,
    orderType_id: 31
  },
  {
    orderGroup_id: 3,
    orderType_id: 5
  },
  {
    orderGroup_id: 3,
    orderType_id: 39
  },
  {
    orderGroup_id: 4,
    orderType_id: 11
  },
  {
    orderGroup_id: 4,
    orderType_id: 24
  },
  {
    orderGroup_id: 5,
    orderType_id: 9
  },
  {
    orderGroup_id: 5,
    orderType_id: 23
  },
  {
    orderGroup_id: 6,
    orderType_id: 25
  },
  {
    orderGroup_id: 6,
    orderType_id: 26
  },
  {
    orderGroup_id: 7,
    orderType_id: 10
  },
  {
    orderGroup_id: 8,
    orderType_id: 15
  },
  {
    orderGroup_id: 9,
    orderType_id: 4
  },
  {
    orderGroup_id: 10,
    orderType_id: 19
  },
  {
    orderGroup_id: 11,
    orderType_id: 21
  },
  {
    orderGroup_id: 12,
    orderType_id: 27
  },
  {
    orderGroup_id: 13,
    orderType_id: 30
  },
  {
    orderGroup_id: 14,
    orderType_id: 32
  },
  {
    orderGroup_id: 15,
    orderType_id: 13
  },
  {
    orderGroup_id: 16,
    orderType_id: 35
  },
  {
    orderGroup_id: 17,
    orderType_id: 36
  },
  {
    orderGroup_id: 18,
    orderType_id: 37
  },
  {
    orderGroup_id: 19,
    orderType_id: 40
  },
  {
    orderGroup_id: 20,
    orderType_id: 41
  },
  {
    orderGroup_id: 21,
    orderType_id: 42
  },
 ]);
