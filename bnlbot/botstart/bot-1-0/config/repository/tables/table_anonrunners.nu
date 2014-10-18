<?xml version="1.0" encoding="ISO-8859-15"?>
<BnlBot xmlns="http://www.nonodev.com/bnlbot" xmlns:xcl="http://www.nonodev.com/bnlbot" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <Table Desc="non runners of market" Name="ANONRUNNERS" Tablespace="" >
        <Column Name="marketid"           Size="11" Type="1"  AllowNull="0" Description="market id"/>
        <Column Name="name"               Size="50" Type="1"  AllowNull="0" Description="name of runner"/>
        <Column Name="ixxlupd"            Size="15" Type="1"  AllowNull="0" Description="Latest updater"/>
        <Column Name="ixxluts"            Size="23" Type="15" AllowNull="0" Description="Latest update timestamp"/>
        <Index Columns="marketid,name" type="primary"/>
        <Index Columns="marketid" type="index"/>
    </Table>
</BnlBot>

