<?xml version="1.0" encoding="UTF-8"?>
<!--
  XHTML to LaTeX Stylesheet von Daniel Mendler <mail at daniel-mendler dot de> (2008)
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0"
		xmlns:chr="http://character-table/">

  <xsl:output method="text"/>
  <xsl:strip-space elements="*"/>
  <xsl:param name="root_path" />
  <xsl:param name="http_host" />

  <chr:char-table>
    <chr:char val="&amp;"  rep="\&amp;" />
    <chr:char val="$"      rep="\$" />
    <chr:char val="#"      rep="\#" />
    <chr:char val="%"      rep="\%" />
    <chr:char val="_"      rep="\_" />
    <chr:char val="{"      rep="\{" />
    <chr:char val="}"      rep="\}" />
    <chr:char val="^"      rep="\^" />
    <chr:char val="~"      rep="\~" />
    <chr:char val="\"      rep="\textbackslash " />
    <chr:char val="&quot;" rep="&apos;&apos;" />
    <chr:char val="°"     rep="$^{\circ}$" />
  </chr:char-table>

  <xsl:template name="string-escape">
    <xsl:param name="string" />
    <xsl:param name="table" select="document('')/xsl:stylesheet/chr:char-table" />

    <xsl:variable name="len" select="string-length($string)" />

    <xsl:if test="$len &gt; 0">
      <xsl:variable name="chr" select="substring($string, 1, 1)" />
      <xsl:variable name="rep" select="string($table/chr:char[@val = $chr]/@rep)" />
      <xsl:choose>
        <xsl:when test="string($rep) = ''">
          <xsl:value-of select="$chr" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$rep" />
        </xsl:otherwise>
      </xsl:choose>

      <xsl:call-template name="string-escape">
        <xsl:with-param name="string" select="substring($string, 2, $len div 2)" />
        <xsl:with-param name="table"  select="$table" />
      </xsl:call-template>

      <xsl:call-template name="string-escape">
        <xsl:with-param name="string" select="substring($string, 2 + $len div 2, $len div 2)" />
        <xsl:with-param name="table"  select="$table" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="include-image">
    <xsl:param  name="src" />
    <xsl:choose>
      <xsl:when test="contains($src, '?')">
        <xsl:text>\includegraphics{</xsl:text><xsl:value-of select="substring-before($src, '?')"/><xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\includegraphics{</xsl:text><xsl:value-of select="$src"/><xsl:text>}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="//text()">
    <xsl:call-template name="string-escape">
      <xsl:with-param name="string" select="."/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="xhtml:html">\documentclass[a4paper,10pt]{article}
\usepackage[utf8]{inputenc}
\usepackage[ngerman]{babel}
\usepackage{longtable}
\usepackage[pdftex]{graphicx}
\usepackage{float}
\usepackage[colorlinks=true,urlcolor=blue,linkcolor=blue]{hyperref}
\usepackage{geometry}
\geometry{a4paper,left=2cm,right=2cm,top=2cm,bottom=2cm}
\setlength{\parindent}{0pt}
\renewcommand{\familydefault}{phv}
\renewcommand{\rmdefault}{phv}
\usefont{\encodingdefault}{\familydefault}{\seriesdefault}{\shapedefault}
\graphicspath{
  {<xsl:value-of select="$root_path"/>}
}

\begin{document}

<xsl:apply-templates select="xhtml:body"/>\end{document}
</xsl:template>

  <xsl:template match="xhtml:h1">
    <xsl:text>\section*{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:h2">
    <xsl:text>\subsection*{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:h3">
    <xsl:text>\subsubsection*{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:br">
    <xsl:text>&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:em">
    <xsl:text>{\em </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:img[@class='math']">
    <xsl:text>\begin{equation}</xsl:text>
    <xsl:value-of select="@alt"/>
    <xsl:text>\end{equation}</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:table//xhtml:img">
    <xsl:call-template name="include-image">
      <xsl:with-param name="src" select="@src"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="xhtml:img">
    <xsl:text>\begin{figure}</xsl:text>
    <xsl:text>\centering</xsl:text>
    <xsl:call-template name="include-image">
      <xsl:with-param name="src" select="@src"/>
    </xsl:call-template>
    <xsl:text>\end{figure}</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:strong">
    <xsl:text>{\bf </xsl:text>
	<xsl:apply-templates/>
	<xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:p">
    <xsl:text>\par&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#10;\par&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:a">
    <xsl:choose>
      <xsl:when test="starts-with(@href, 'http') or starts-with(@href, 'mailto')">
        <xsl:text>\href{</xsl:text><xsl:value-of select="@href"/>}{<xsl:apply-templates/><xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\href{</xsl:text><xsl:value-of select="concat($http_host, @href)"/>}{<xsl:apply-templates/><xsl:text>}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="xhtml:select|xhtml:input"/>

  <xsl:template match="xhtml:table">
    <xsl:text>\begin{table}[H]</xsl:text>
    <xsl:for-each select="xhtml:caption">
      <xsl:text>\caption{</xsl:text>
      <xsl:apply-templates/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>\begin{longtable}{|</xsl:text>
    <xsl:for-each select="//xhtml:tr[1]/*">
      <xsl:text>l|</xsl:text>
    </xsl:for-each>
    <xsl:text>}&#10;</xsl:text>
    <xsl:apply-templates select="*[not(self::xhtml:caption)]"/>
    <xsl:text>\hline&#10;</xsl:text>
    <xsl:text>\end{longtable}&#10;\end{table}&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:thead">
    <xsl:apply-templates/>
    \hline&#10;
  </xsl:template>

  <xsl:template match="xhtml:tr">
    <xsl:text>\hline&#10;</xsl:text>
    <xsl:for-each select="*">
      <xsl:if test="@colspan">\multicolumn{<xsl:value-of select="@colspan"/>}{l|}{</xsl:if>
      <xsl:if test="name() = 'th'">{\bf </xsl:if>
      <xsl:apply-templates />
      <xsl:if test="name() = 'th'">}</xsl:if>
      <xsl:if test="@colspan">}</xsl:if>
      <xsl:if test="position() != last()">
        <xsl:text> &amp; </xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:text> \\&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:ul">
    <xsl:text>\begin{itemize}&#10;</xsl:text>
    <xsl:for-each select="xhtml:li">
      <xsl:text>  \item{</xsl:text>
      <xsl:apply-templates />
      <xsl:text>}&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>\end{itemize}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xhtml:ol">
    <xsl:text>\begin{enumerate}
    </xsl:text>
    <xsl:for-each select="xhtml:li">
      <xsl:text>\item </xsl:text>
      <xsl:apply-templates />
    </xsl:for-each>
    <xsl:text>
      \end{enumerate}
    </xsl:text>
  </xsl:template>

</xsl:stylesheet>
