<?xml version="1.0" encoding="ISO-8859-15"?>
<MaAstro>
    <Table Wiz="3" Desc="Bets" Name="ABETHISTORY" Tablespace="">
        <Column Name="betid"            Size="18"  Type="3"  AllowNull="0" Description="bet id"/>
        <Column Name="powerdays"        Size="9"   Type="2"  AllowNull="0" Description="power of denominator"/>
        <Column Name="startts"          Size="23"  Type="15" AllowNull="1" Description="start ts according to market"/>
        <Column Name="historysum"       Size="8"   Type="6"  AllowNull="0" Description="sum"/>
        <Column Name="ixxlupd"          Size="15"  Type="1"  AllowNull="0" Description="Latest updater"/>
        <Column Name="ixxluts"          Size="23"  Type="15" AllowNull="0" Description="Latest update timestamp"/>
        <Index Columns="betid,powerdays" type="primary"/>
        <Index Columns="startts" type="index"/>
    </Table>
</MaAstro>
