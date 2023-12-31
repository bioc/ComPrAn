#'  Compare a Two Groups of Proteins Within One Label State
#'
#' This function creates a scatter plot for a subset of proteins in dataFrame 
#' specified in group1Data and group2Data, label states are always separated 
#' into facets
#' 
#' Intended use of the function - using scenario A data, compare shape of the
#' migration profile between a TWO GROUPS of proteins WITHIN the ONE 
#' LABEL STATE
#' @param dataFrame dataFrame: data frame, data frame of normalised values for 
#'         proteins from SCENARIO A,
#'            contains columns:
#'           `Protein Group Accessions` character
#'           `Protein Descriptions` character
#'            Fraction integer
#'            isLabel character ('TRUE'/'FALSE' values)
#'            `Precursor Area` double
#'            scenario character
#' @param max_frac numeric, total number of fractions
#' @param group1Data character vector, contins list of Protein Group Accessions
#'  that belong to the group we want to plot for group 1
#' @param group1Name character, name that should be used for the group 
#' specified in group1Data
#' @param group2Data character vector, contins list of Protein Group Accessions 
#' that belong to the group we want to plot for group 2
#' @param group2Name character, name that should be used for the group 
#' specified in group2Data
#' @param meanLine logical, specifies whether to plot a mean line for all 
#' values in the group
#' @param medianLine logical, specifies whether to plot a median line for all 
#' values in the group
#' @param ylabel character
#' @param xlabel character
#' @param legendLabel character
#' @param labelled character, label to be used for isLabel == TRUE
#' @param unlabelled character, label to be used for isLabel == FALSE
#' @param jitterPoints numeric
#' @param pointSize numeric, size of the point in the plot
#' @param grid logical, specifies presence/absence of gridline in the plot
#' @param showTitle logical
#' @param titleAlign character, one of the 'left', 'center'/'centre', 'right',
#'  specifies alignment of the title in plot
#' @param alphaValue numeric, transparency of the point, values 0 to 1
#' @param textSize numeric, size of text in the plot 
#' @param axisTextSize numeric, size of axis labels in the plot
#'
#' @return plot
#' @export
#' 
#' @examples
#' ##Use example normalised proteins file
#' inputFile <- system.file("extData", "dataNormProts.txt", package ="ComPrAn")
#' #read file in and change structure of table to required format
#' forAnalysis <- protImportForAnalysis(inputFile)
#' ##example plot:
#' g1D <- c("Q16540","P52815","P09001","Q13405","Q9H2W6") #group 1 data vector
#' g1N <- 'group1'                                        #group 1 name
#' g2D <- c("Q9NVS2","Q9NWU5","Q9NX20","Q9NYK5","Q9NZE8") #group 2 data vector
#' g2N <- 'group2'                                        #group 2 name
#' max_frac <- 23 
#' twoGroupsWithinLabelCoMigration(forAnalysis, max_frac, g1D, g1N, g2D, g2N)
twoGroupsWithinLabelCoMigration <- function(dataFrame,max_frac,group1Data=NULL,
    group1Name='group1',group2Data=NULL,group2Name='group2',meanLine = FALSE,
    medianLine = FALSE,ylabel='Relative Protein Abundance',xlabel='Fraction',
    legendLabel='Group',labelled = "Labeled",unlabelled = "Unlabeled",
    jitterPoints = 0.3, pointSize = 2.5,grid = FALSE, showTitle = FALSE,
    titleAlign = 'left',alphaValue = 1,textSize = 12, axisTextSize = 8){
    if(is.null(group1Data)|is.null(group2Data)) {
        stop('Please provide a list of group1 proteins and group2 
                proteins you would like to plot')}
    col_vector2 =c('#D81B60','#1E88E5')
    names(col_vector2) = c(group1Name,group2Name)
    dataFrame <- dataFrame[dataFrame$scenario == "A",] #filter only scenario A
    dataFrame %>% select(-scenario) ->dataFrame
    group1Data <- data.frame(protein = group1Data, group = rep(
        group1Name,length(group1Data)), stringsAsFactors=FALSE)
    group2Data <- data.frame(protein = group2Data, group = rep(
        group2Name,length(group2Data)), stringsAsFactors=FALSE)
    jointGroupData <- rbind(group1Data, group2Data)
    jointGroupData %>%
        rename(`Protein Group Accessions` = protein)-> jointGroupData
    inner_join(dataFrame, jointGroupData) -> dataFrame
    data.frame(Value = NA, Fraction = seq_len(max_frac)) %>%
        spread(Fraction, "Value") -> padding
    dataFrame %>%
        spread(Fraction, `Precursor Area`) %>%
        merge(padding, all.x = TRUE) %>%
        gather(Fraction, `Precursor Area`, -c(`Protein Group Accessions`,isLabel
                                            ,group,`Protein Descriptions`)) %>%
        group_by(Fraction, isLabel, group) %>%
        mutate (meanValue = mean(`Precursor Area`, na.rm = TRUE)) %>%
        mutate (medianValue = median(`Precursor Area`, na.rm = TRUE)) %>%
        ungroup() -> dataFrame
    dataFrame$Fraction <- as.numeric(as.character(dataFrame$Fraction))
    linetype_vector <- c('twodash', 'solid')     #define linetype_vector
    names(linetype_vector) <- c('mean','median')
    p <- ggplot(dataFrame, aes(x =Fraction, y=`Precursor Area`,col = group)) +
        geom_point(position = position_jitter(jitterPoints),
                    alpha = alphaValue, size = pointSize, na.rm =TRUE) +
        scale_color_manual(legendLabel, values=col_vector2) +
        scale_fill_manual(legendLabel, values=col_vector2) +
        ylab(ylabel) + xlab(xlabel) +
        scale_x_continuous(breaks=seq_len(max_frac),minor_breaks = NULL)+
        scale_y_continuous(breaks=seq(0,1,0.2))+
        scale_linetype_manual('Line type', values = linetype_vector)+
        facet_wrap(isLabel ~ ., ncol =1, labeller = labeller(
            isLabel = c("TRUE" = labelled,"FALSE" = unlabelled)))
    if(showTitle){p<-p +labs(title=paste(group1Name,' and ',group2Name,sep=''))}
    if(meanLine) {  ## add line that is a mean of all protein values
        p <- p + geom_line(aes(y=meanValue, col = group, linetype = 'mean'), 
                            size = 1, na.rm = TRUE)
    }
    if (medianLine) { ##  add line that is a median of all protein values
        p <- p + geom_line(aes(y = medianValue, col = group, linetype='median'),
                            size=1, na.rm = TRUE)
    }
    if(grid){p<- p +theme_minimal() +     #add grid
        theme(panel.grid.minor = element_blank())
    } else {p<- p +theme_classic()}
    if (titleAlign == 'left'){adjust <- 0     #title alignment settings
    } else if ((titleAlign == 'centre')|(titleAlign=='center')) {adjust <- 0.5
    } else if(titleAlign == 'right'){adjust <- 1}
    p <- p + theme(plot.title = element_text(hjust = adjust),
    text=element_text(size=textSize),axis.text=element_text(size=axisTextSize))
    return(p)
}