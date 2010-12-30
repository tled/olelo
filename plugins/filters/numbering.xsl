<?xml version="1.0" encoding="UTF-8"?>
<!--
  Add headline numbering to XHTML
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0">

  <xsl:output method="xml"
	      version="1.0"
	      encoding="UTF-8"
	      doctype-public="-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN"
	      doctype-system="http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg-flat.dtd" indent="yes"/>

  <xsl:strip-space elements="*"/>

  <!-- Identity template -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xhtml:h2">
    <xsl:variable name="number">
      <xsl:number count="xhtml:h2" level="any"/>
    </xsl:variable>
    <h2 id="s{$number}">
      <span class="number"><xsl:value-of select="$number"/></span>
      <xsl:text>
      </xsl:text>
      <xsl:apply-templates select="@*|node()"/>
    </h2>
  </xsl:template>

  <xsl:template match="xhtml:h3">
    <xsl:variable name="number">
      <xsl:number count="xhtml:h2" level="any" format="1."/>
      <xsl:number count="xhtml:h3" from="xhtml:h2" level="any"/>
    </xsl:variable>
    <h3 id="s{$number}">
      <span class="number"><xsl:value-of select="$number"/></span>
      <xsl:text>
      </xsl:text>
      <xsl:apply-templates select="@*|node()"/>
    </h3>
  </xsl:template>

  <xsl:template match="xhtml:h4">
    <xsl:variable name="number">
      <xsl:number count="xhtml:h2" level="any" format="1."/>
      <xsl:number count="xhtml:h3" from="xhtml:h2" level="any" format="1."/>
      <xsl:number count="xhtml:h4" from="xhtml:h3" level="any"/>
    </xsl:variable>
    <h4 id="s{$number}">
      <span class="number"><xsl:value-of select="$number"/></span>
      <xsl:text>
      </xsl:text>
      <xsl:apply-templates select="@*|node()"/>
    </h4>
  </xsl:template>

  <xsl:template match="xhtml:h5">
    <xsl:variable name="number">
      <xsl:number count="xhtml:h2" level="any" format="1."/>
      <xsl:number count="xhtml:h3" from="xhtml:h2" level="any" format="1."/>
      <xsl:number count="xhtml:h4" from="xhtml:h3" level="any" format="1."/>
      <xsl:number count="xhtml:h5" from="xhtml:h4" level="any"/>
    </xsl:variable>
    <h5 id="s{$number}">
      <span><xsl:value-of select="$number"/></span>
      <xsl:text>
      </xsl:text>
      <xsl:apply-templates select="@*|node()"/>
    </h5>
  </xsl:template>

  <xsl:template match="xhtml:h6">
    <xsl:variable name="number">
      <xsl:number count="xhtml:h2" level="any" format="1."/>
      <xsl:number count="xhtml:h3" from="xhtml:h2" level="any" format="1."/>
      <xsl:number count="xhtml:h4" from="xhtml:h3" level="any" format="1."/>
      <xsl:number count="xhtml:h5" from="xhtml:h4" level="any" format="1."/>
      <xsl:number count="xhtml:h6" from="xhtml:h5" level="any"/>
    </xsl:variable>
    <h6 id="s{$number}">
      <span class="number"><xsl:value-of select="$number"/></span>
      <xsl:text>
      </xsl:text>
      <xsl:apply-templates select="@*|node()"/>
    </h6>
  </xsl:template>

</xsl:stylesheet>
