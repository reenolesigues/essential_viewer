<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xpath-default-namespace="http://protege.stanford.edu/xml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xalan="http://xml.apache.org/xslt" xmlns:pro="http://protege.stanford.edu/xml" xmlns:eas="http://www.enterprise-architecture.org/essential" xmlns:functx="http://www.functx.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ess="http://www.enterprise-architecture.org/essential/errorview">
    <xsl:import href="../../common/core_js_functions.xsl"/>
    <xsl:include href="../../common/core_roadmap_functions.xsl"/>
	<xsl:output method="text" encoding="UTF-8"/>
	<xsl:param name="param1"/>
    <xsl:variable name="allAppProviders" select="/node()/simple_instance[(type = 'Application_Provider') or (type = 'Composite_Application_Provider')][name=$param1]"/>
    <xsl:variable name="inScopeCosts" select="/node()/simple_instance[own_slot_value[slot_reference = 'cost_for_elements']/value = $allAppProviders/name]"/>
<!--
	<xsl:variable name="inScopeCostComponents" select="/node()/simple_instance[name = $inScopeCosts/own_slot_value[slot_reference = 'cost_components']/value]"/>
	<xsl:variable name="inScopeCostInstances" select="$inScopeCosts union $inScopeCostComponents"></xsl:variable>
--><xsl:variable name="costType" select="/node()/simple_instance[(type = 'Cost_Component_Type')]"/>
	<xsl:variable name="currencyType" select="/node()/simple_instance[(type = 'Report_Constant')][own_slot_value[slot_reference = 'name']/value='Default Currency']"/>
	<xsl:variable name="currency" select="/node()/simple_instance[(type = 'Currency')][name=$currencyType/own_slot_value[slot_reference = 'report_constant_ea_elements']/value]/own_slot_value[slot_reference='currency_symbol']/value"/>
    <!--
 <xsl:variable name="isAuthzForCostInstances" select="eas:isUserAuthZInstances($thisinScopeCostInstances)"/>
   -->

    
    <xsl:variable name="allRoadmapInstances" select="$allAppProviders"/>
    <xsl:variable name="isRoadmapEnabled" select="eas:isRoadmapEnabled($allRoadmapInstances)"/>
	<xsl:variable name="rmLinkTypes" select="$allRoadmapInstances/type"/>
    <!--
		* Copyright © 2008-2019 Enterprise Architecture Solutions Limited.
	 	* This file is part of Essential Architecture Manager, 
	 	* the Essential Architecture Meta Model and The Essential Project.
		*
		* Essential Architecture Manager is free software: you can redistribute it and/or modify
		* it under the terms of the GNU General Public License as published by
		* the Free Software Foundation, either version 3 of the License, or
		* (at your option) any later version.
		*
		* Essential Architecture Manager is distributed in the hope that it will be useful,
		* but WITHOUT ANY WARRANTY; without even the implied warranty of
		* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		* GNU General Public License for more details.
		*
		* You should have received a copy of the GNU General Public License
		* along with Essential Architecture Manager.  If not, see <http://www.gnu.org/licenses/>.
		* 
	-->
	<!-- 03.09.2019 JP  Created	 -->
	
    	<xsl:template match="knowledge_base">
		{
			"applicationCost": [
				<xsl:apply-templates mode="RenderApplications" select="$allAppProviders">
					<xsl:sort select="own_slot_value[slot_reference = 'name']/value"/>
				</xsl:apply-templates>
			]   
		}
	</xsl:template>
    <xsl:template mode="RenderApplications" match="node()">                           
         <xsl:variable name="inScopeCosts" select="/node()/simple_instance[own_slot_value[slot_reference = 'cost_for_elements']/value = $allAppProviders/name]"/>
        <xsl:variable name="inScopeCostComponents" select="/node()/simple_instance[name = $inScopeCosts/own_slot_value[slot_reference = 'cost_components']/value]"/>
		{
			<xsl:call-template name="RenderRoadmapJSONPropertiesDataAPI"><xsl:with-param name="isRoadmapEnabled" select="$isRoadmapEnabled"/><xsl:with-param name="theRoadmapInstance" select="current()"/><xsl:with-param name="theDisplayInstance" select="current()"/><xsl:with-param name="allTheRoadmapInstances" select="$allRoadmapInstances"/></xsl:call-template>,
            "costs":[<xsl:for-each select="$inScopeCostComponents">
                    {"id":"<xsl:value-of select="eas:getSafeJSString(current()/name)"/>","name":"<xsl:value-of select="$costType[name=current()/own_slot_value[slot_reference='cc_cost_component_type']/value]/own_slot_value[slot_reference='name']/value"/>","cost":"<xsl:value-of select="current()/own_slot_value[slot_reference='cc_cost_amount']/value"/>","currency":"<xsl:value-of select="$currency"/>"}<xsl:if test="not(position()=last())">,</xsl:if>           
                </xsl:for-each>]
        <!--
		"change":"<xsl:choose><xsl:when test="not($isAuthzForCostClasses) or not($isAuthzForCostInstances)"></xsl:when>	<xsl:otherwise>
                                		<xsl:variable name="costTypeTotal" select="eas:get_cost_components_total($thisinScopeCostComponents, 0)"/>
                                		<xsl:choose>
                                			<xsl:when test="$costTypeTotal=0"></xsl:when>
                                			<xsl:otherwise>
                                				<xsl:value-of select="$currency"/>  <xsl:value-of select="format-number($costTypeTotal, '###,###,###')"/>
                                			</xsl:otherwise>
                                		</xsl:choose>
                                	</xsl:otherwise>
                             </xsl:choose>"
-->		} <xsl:if test="not(position()=last())">,</xsl:if>
	</xsl:template>

     <xsl:function as="xs:float" name="eas:get_cost_components_total">
        <xsl:param name="costComponents"/>
        <xsl:param name="total"/>
        
        <xsl:choose>
            <xsl:when test="count($costComponents) > 0">
                <xsl:variable name="nextCost" select="$costComponents[1]"/>
                <xsl:variable name="newCostComponents" select="remove($costComponents, 1)"/>
                <xsl:variable name="costAmount" select="$nextCost/own_slot_value[slot_reference='cc_cost_amount']/value"/>
                <xsl:choose>
                    <xsl:when test="$costAmount > 0">
                        <xsl:value-of select="eas:get_cost_components_total($newCostComponents, $total + number($costAmount))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="eas:get_cost_components_total($newCostComponents, $total)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$total"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>
   

