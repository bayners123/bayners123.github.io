---
---
# Jose group members scroller

# Not for release ever
# Created by Charles Baynham

# To be called on the .fullHolder element

# Data: 29 Jul 2014

# (c) 2014 by Charles Baynham

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

(($,window,document) -> 
    
    pluginName = "groupScroller"
    defaults = 
        leftArrow: null
        rightArrow: null
        minusArrow: null
        plusArrow: null
        personHeading: null
        slideImgHolder: null
        descULHolder: null
        groupListHolder: null
        first: "middle"
    
    data = 
        leftArrow: null
        rightArrow: null
        personHeading: null
        currentYear: 0 # 0 based index of groupInfo. 0 initially. 
        currentSlide: null # of current year
        noSlides: null # of current year
        
        groupInfo: []
        # groupInfo is an array containing pointers to all the group's info in the HTML
        # It is structured as shown:
        #
        # groupInfo = array
        #     - year: string
        #       image: element
        #       descUL: element
        #       nav: element
        #
        #     - year: ...
                  
        
        slideImg: null
        descUL: null
    
    class Plugin
      constructor: (@element, options) ->
        @options = $.extend true, {}, defaults, options
        @_defaults = defaults
        @_name = pluginName
        @data = data
        @init()

    Plugin::init = ->
        $element = $(@element)
        
        # Get various elements if not provided
        if @options.leftArrow
            @data.leftArrow = $(@options.leftArrow)
        else
            @data.leftArrow = $element.find(".groupDesc .arrow.left")
            
        if @options.rightArrow
            @data.rightArrow = $(@options.rightArrow)
        else
            @data.rightArrow = $element.find(".groupDesc .arrow.right")
            
        if @options.minusArrow
            @data.minusArrow= $(@options.minusArrow)
        else
            @data.minusArrow= $element.find(".yearBox .arrow.left")
            
        if @options.plusArrow
            @data.plusArrow= $(@options.plusArrow)
        else
            @data.plusArrow= $element.find(".yearBox .arrow.right")
            
        if @options.personHeading
            @data.personHeading = $(@options.personHeading)
        else
            @data.personHeading = $element.find(".groupDesc .person")
            
        # find the slideImgHolder
        if @options.slideImgHolder
            slideImgHolder = $(@options.slideImgHolder)
        else
            slideImgHolder = $element.find(".imgHolder")
            
        # loop through all images in it, getting their years & hiding all except the first
        $.each slideImgHolder.children("img"), (index) =>
            
            $img = slideImgHolder.children("img").eq(index)
            year = $img.data("year")
            @data.groupInfo.push 
                year: year
                image: $img
                
            $img.hide() unless index == 0
        
        # set slideImg to the first img
        @data.slideImg = @data.groupInfo[0].image
        
        if @options.descULHolder
            descULHolder = $(@options.descULHolder)
        else
            descULHolder = $element.find(".descHolder")
            
        # Loop through all ULs of descriptions, storing them & hiding all except the first
        $.each descULHolder.children("ul"), (index) =>
            
            $ul = descULHolder.children("ul").eq(index)
            if @data.groupInfo[index].year != $ul.data("year")
                console.log "Error: order of descHolder ul elements is mismatched with imgs"
            @data.groupInfo[index].descUL = $ul
            
            $ul.hide() unless index == 0
        
        if @options.groupListHolder
            groupListHolder = @options.groupListHolder
        else
            groupListHolder = $element.find(".groupListHolder")
            
        # Loop through all NAVs of links, storing them too & hiding all except the first
        $.each groupListHolder.children("nav"), (index) =>
            
            $nav = groupListHolder.children("nav").eq(index)
            if @data.groupInfo[index].year != $nav.data("year")
                console.log "Error: order of nav elements is mismatched with imgs"
            @data.groupInfo[index].nav = $nav
            
            $nav.hide() unless index == 0
        
        # Number of slides:
        @data.noSlides = @data.groupInfo[0].descUL.children("li").length
        
        # Register left and right arrows
        @data.leftArrow.on "click.groupMembers", =>
            @_prev()
            false
        @data.rightArrow.on "click.groupMembers", =>
            @_next()
            false
            
        # Bind the .groupList nav to the slides
        # We expect that the .groupList contains the same number of a elements as there are group members
        $.each @data.groupInfo, (index) =>
            @data.groupInfo[index].nav.children("a").click (e) =>
            
                # Get the clicked link
                clickedLink = e.target
            
                # Disable the hyperlink
                e.preventDefault()
            
                # Goto the appropriate slide, with animation
                @_goto @data.groupInfo[index].nav.children("a").index(clickedLink), true
            
            
        # Zoom the image and goto the first slide on load
        $ =>
            # Set images to zoom to fill the area using the zoomImage plugin
            $.each @data.groupInfo, (index) =>
                @data.groupInfo[index].image.zoomImage
                    # Whenever the image gets resized, update skrollr
                    # Only bind this for the first image, otherwise we'll just fire it multiple times
                    resizeCallbackAfter: if index==0 then ->
                        if skrollr?
                          if skrollr.get()
                            skrollr.get().refresh()
                    else $.noop
                    # Before the image gets resized, recalculate the xMargin
                    useMarginFunctions: true
                    initialAnimation: false
                    getXOverride: =>
                        @getXMargin(@data.currentSlide)
                
            # Re-scroll skrollr if needed
            if (skrollr && skrollr.menu)
                skrollr.menu.jumpToInitialPos()
            
            # Calculate the middle slide if requested
            if @options.first == "middle"
                @options.first = Math.floor((@data.noSlides - 1) / 2)
            
            # Goto first slide with no animation
            @_goto(@options.first, false)
        
    Plugin::_prev = ->
        
        # Call @_goto with animation
        if @data.currentSlide != 0
            # altered
            @_goto(@data.currentSlide - 1, true)
        
    Plugin::_next = ->
        
        # Call @_goto with animation
        if @data.currentSlide < @data.noSlides - 1
            # altered
            @_goto(@data.currentSlide + 1, true)
        
        # all this altered
    Plugin::_goto = (slide, animation) ->
        
        # Check the argument is valid
        if 0 <= slide < @data.noSlides
            # Get all the list items (the slides)
            $slides = @data.groupInfo[@data.currentYear].descUL.children("li")
            $thisSlide = $slides.eq(slide)
            $groupListLinks = @data.groupInfo[@data.currentYear].nav.children("a")
            
            # Hide all slides
            $slides.hide()
        
            # Show the correct one
            $thisSlide.show()
            
            # Set the person's name
            @data.personHeading.html $thisSlide.data("person")
            
            # Remove all 'active' classes from person list
            $groupListLinks.removeClass('active')
            
            # Add 'active' class to correct person
            $groupListLinks.eq(slide).addClass('active')
            
            # Update the current slide
            @data.currentSlide = slide
            
            # Hide the arrow if we've reached far left/right
            if slide == 0
              @data.leftArrow.hide()
              @data.rightArrow.show()
            else if slide == @data.noSlides-1
              @data.leftArrow.show()
              @data.rightArrow.hide()
            else
              @data.leftArrow.show()
              @data.rightArrow.show()              
            
            # Resize the image (using animation). This will cause zoomImage to call getXMargin to determine the correct offset
            @data.slideImg.data("plugin_zoomImage").resize(animation)
            
            
    Plugin::getXMargin = (slide) ->
        
        # Calculate the left margin value required for the image. 
        # Remember, this is a percentage of the parent's width
        # This should cause the image to go evenly between the far left and the far right when in horizontal mode
        
        # The far left value = 0
        # The far right value = - (imgWidth - parentWidth) / parentWidth * 100
        #                     = - (imgWidth/parentWidth - 1) * 100
        
        imgWidth = @data.groupInfo[@data.currentYear].image.width()
        parentWidth = $(@element).width()
        # =>
        farRight = - (imgWidth / parentWidth - 1) * 100
        
        # We want to go somewhere between max and min, depending on which slide we're on:
        xMargin = 0 + farRight * slide / (@data.noSlides - 1)
        
        return xMargin
        
        
    # Plugin constructor
    $.fn[pluginName] = (options) ->
      @each ->
        if !$.data(@, "plugin_#{pluginName}")
          $.data(@, "plugin_#{pluginName}", new Plugin(@, options))
    
)(jQuery, window, document)
