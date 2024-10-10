macro "Edge detector" {
    // Initialize variables
    var width, height, x_points, y_points, imgID, pointsID;
    var scan_direction = "Y";
    var interval, unit, pixelWidth, pixelHeight;
    var y_scan_direction = "↓"; //↑↓
	var smoothing_number = 0 ;
	var close_kymo = true ;
	var detection_method = "Gradient" ;
	var RecWidth = 40;
	var RecHeight = 20 ;
    // Open the image if not already open
    imgID = getImageID();;
    Stack.setChannel(1);
    //Stack.setActiveChannels("10"); 
    interval = getInfo("Frame interval (s)");
    getPixelSize(unit, pixelWidth, pixelHeight);
    if (interval == "") {
        interval = Stack.getFrameInterval();
        if (interval == "") {
            interval = 1;
        }
    }

    // Get image dimensions
    width = getWidth();
    height = getHeight();
    
    // Initialize arrays for transition points
    x_points = newArray(0);
    y_points = newArray(0);
    
    // Set up the interactive tool
    setTool("rectangle");
	selectImage(imgID);
    while (true) {

         

        width = getWidth();
    	height = getHeight();
    
		
		getCursorLoc(x, y, z, flags);
        
        if (flags == 8|87) { 
            roiManager("deselect");
            roiManager("delete");
            Overlay.remove;
            setTool("polyline");
            exit();
        } else if (flags == 16 |1) { 
            findTransitionPoints(x, y, scan_direction);
            
            wait(100);
        } else if (flags == (8 | 1)) { 
            removeROIs(x - (RecWidth / 2), y - (RecHeight / 2), x + (RecWidth / 2), y + (RecHeight / 2));
            wait(100);
        } else if (flags == (8 | 2)) {
            imageName = getTitle();
            saveROIsToCSV(imageName, 1);
		} else if (flags == (8)) {
			Dialog.create("Settings");
			getPixelSize(unit, pixelWidth, pixelHeight);
			Dialog.addMessage("Scale:" + pixelWidth + unit);
			Dialog.addMessage("Frame interval:" + interval);
		    Dialog.addSlider("Rectangle width", 2, 100, RecWidth);
		    Dialog.addSlider("Rectangle height", 2, 100, RecHeight);
		    Dialog.addSlider("smoothing", 0, 10, 0);
		    Dialog.addRadioButtonGroup("Transition detection method", newArray("Gradient", "Maximum", "Gaussian fit"), 1, 3, detection_method);
		    Dialog.addRadioButtonGroup("Scan direction", newArray("X", "Y", "Both"), 1, 3, scan_direction);
		    Dialog.addRadioButtonGroup("Y scan direction", newArray("↓", "↑"), 1, 2, y_scan_direction);
		    Dialog.addCheckbox("Flip image horizontally", false);
		    Dialog.addCheckbox("Make polyline", false);
		    Dialog.show();
		    
		    RecWidth = Dialog.getNumber();
		    RecHeight = Dialog.getNumber();
		    smoothing_number = Dialog.getNumber();
		    detection_method = Dialog.getRadioButton();

		    scan_direction = Dialog.getRadioButton();
		    y_scan_direction = Dialog.getRadioButton();
		    flip_image = Dialog.getCheckbox();
		    make_polyline = Dialog.getCheckbox();
		    for(p=0 ; p<smoothing_number; p++){
		        run("Select All");
		        run("Smooth");
		    }
		    if(flip_image){
		        run("Select All");
		        run("Flip Horizontally");
		    }
		    if(make_polyline){
		        createPolylineFromROIs();
		    }
		    wait(100);
		} else if (flags == 16) {
			count = roiManager("count");
			if(count != 0){
            roiManager("deselect");
            roiManager("delete");}
            else{
            Overlay.remove;
            setTool("polyline");
            exit();
            }
            wait(100);
        }
        
        Overlay.remove ; 
        makeRectangle(x - (RecWidth / 2), y - (RecHeight / 2), RecWidth, RecHeight);
        Overlay.addSelection("yellow");
        Overlay.show;


        
        wait(50);
        
    }
    
function createPolylineFromROIs() {
    nRois = roiManager("count");
    if (nRois == 0) return;
    
    Dialog.create("Polyline Options");
    Dialog.addNumber("Number of points for polyline (max " + nRois + ")", nRois);
    Dialog.addCheckbox("Fit spline", false);
    Dialog.show();
    
    fitPoints = Dialog.getNumber();
    fitSpline = Dialog.getCheckbox();
    
    // Ensure fitPoints is within valid range
    fitPoints = Math.max(2, Math.min(fitPoints, nRois));
    
    x_points = newArray(nRois);
    y_points = newArray(nRois);
    
    for (i = 0; i < nRois; i++) {
        roiManager("select", i);
        Roi.getCoordinates(x, y);
        x_points[i] = x[0];
        y_points[i] = y[0];
    }
    
    // Sort points based on scanning direction
    if (scan_direction == "X") {
        // Sort based on y-points (low to high) for X-direction scanning
        for (i = 0; i < nRois - 1; i++) {
            for (j = 0; j < nRois - i - 1; j++) {
                if (y_points[j] > y_points[j + 1]) {
                    temp = y_points[j]; y_points[j] = y_points[j + 1]; y_points[j + 1] = temp;
                    temp = x_points[j]; x_points[j] = x_points[j + 1]; x_points[j + 1] = temp;
                }
            }
        }
    } else if (scan_direction == "Y") {
        // Sort based on x-points (low to high) for Y-direction scanning
        for (i = 0; i < nRois - 1; i++) {
            for (j = 0; j < nRois - i - 1; j++) {
                if (x_points[j] > x_points[j + 1]) {
                    temp = x_points[j]; x_points[j] = x_points[j + 1]; x_points[j + 1] = temp;
                    temp = y_points[j]; y_points[j] = y_points[j + 1]; y_points[j + 1] = temp;
                }
            }
        }
    }
    
    // Create arrays for the fitted points
    x_fit = newArray(fitPoints);
    y_fit = newArray(fitPoints);
    
    // Calculate the iteration step
    step = (nRois - 1) / (fitPoints - 1);
    
    // Fill the fitted arrays
    for (i = 0; i < fitPoints; i++) {
        index = Math.round(i * step);
        x_fit[i] = x_points[index];
        y_fit[i] = y_points[index];
    }
    
    // Create polyline
    if (fitSpline) {
        makeSelection("polyline", x_fit, y_fit);
        run("Fit Spline");
    } else {
        makeSelection("polyline", x_fit, y_fit);
    }
    
    Roi.setPosition(0, 0, 0);
    roiManager("add");
    newPolylineIndex = roiManager("count") - 1;
    roiManager("select", newPolylineIndex);
    roiManager("rename", "Polyline");
    
    // Remove all point ROIs
    for (i = nRois - 1; i >= 0; i--) {
        roiManager("select", i);
        roiManager("delete");
    }
    
    // Select and show the new polyline
    roiManager("select", 0);
    roiManager("show all without labels");
}
    // Chung-Kennedy filter function
    function chung_kennedy_filter(x, M, K, p) {
        N = x.length;
        y = newArray(N);
        for (i = 0; i < N; i++) {
            if (i < M) {
                sum = 0;
                for (j = 0; j <= i; j++) {
                    sum += x[j];
                }
                y[i] = sum / (i + 1);
            } else if (i >= N - M) {
                sum = 0;
                for (j = i; j < N; j++) {
                    sum += x[j];
                }
                y[i] = sum / (N - i);
            } else {
                forward = 0;
                backward = 0;
                V_f = 0;
                V_b = 0;
                for (j = 0; j < M; j++) {
                    forward += x[i + j];
                    backward += x[i - M + 1 + j];
                }
                forward /= M;
                backward /= M;
                for (j = 0; j < M; j++) {
                    V_f += (x[i + j] - forward) * (x[i + j] - forward);
                    V_b += (x[i - M + 1 + j] - backward) * (x[i - M + 1 + j] - backward);
                }
                V_f /= M;
                V_b /= M;
                W_f = 1 / pow(V_f + K, p);
                W_b = 1 / pow(V_b + K, p);
                y[i] = (W_f * forward + W_b * backward) / (W_f + W_b);
            }
        }
        return y;
    }

function findTransitionPoints(centerX, centerY, scan_direction) {
    startX = Math.max(0, centerX - RecWidth / 2);
    endX = Math.min(width - 1, centerX + RecWidth / 2);
    startY = Math.max(0, centerY - RecHeight / 2);
    endY = Math.min(height - 1, centerY + RecHeight / 2);

    x_points = newArray(0);
    y_points = newArray(0);

    if (scan_direction == "Y" || scan_direction == "Both") {
        for (x = startX; x <= endX; x++) {
            column = newArray(endY - startY + 1);
            for (y = startY; y <= endY; y++) {
                column[y - startY] = getPixel(x, y);
            }
            if (y_scan_direction == "↑") {
                column = Array.reverse(column);
            }
            filtered_column = chung_kennedy_filter(column, 5, 3, 20);
            if (detection_method == "Gradient") {
                y_transition = find_y_transition(filtered_column);
            } else if (detection_method == "Maximum"){
                y_transition = find_max_value(column);
            }
			else if (detection_method == "Gaussian fit") {
                    y_transition = gaussian_fit(column);
                }

            if (y_transition >= 0) {
                if(y_scan_direction == "↓"){
                    y_transition_global = startY + y_transition;
                }
                else {
                    y_transition_global = endY - y_transition;
                }
                x_points = Array.concat(x_points, x);
                y_points = Array.concat(y_points, y_transition_global);
            }
        }
    }

    if (scan_direction == "X" || scan_direction == "Both") {
        for (y = startY; y <= endY; y++) {
            row = newArray(endX - startX + 1);
            for (x = startX; x <= endX; x++) {
                row[x - startX] = getPixel(x, y);
            }
            filtered_row = chung_kennedy_filter(row, 5, 3, 20);

            if (detection_method == "Gradient") {
                x_transition = find_x_transition(filtered_row);
            } 
			else if (detection_method == "Gaussian fit") {
                    x_transition = gaussian_fit(row);
                }
            else {
                x_transition = find_max_value(row);
            }
            
            
            if (x_transition >= 0) {
                x_transition_global = startX + x_transition;
                x_points = Array.concat(x_points, x_transition_global);
                y_points = Array.concat(y_points, y);
            }
        }
    }

    // Remove existing ROIs in the area
    nRois = roiManager("count");
    for (i = nRois - 1; i >= 0; i--) {
        roiManager("select", i);
        getSelectionBounds(rx, ry, rw, rh);
        if (rx >= startX && rx <= endX && ry >= startY && ry <= endY) {
            roiManager("delete");
        }
    }
    
    // Add new points as ROIs
    for (i = 0; i < x_points.length; i++) {
        makePoint(x_points[i], y_points[i]);
        Roi.setPosition(0, 0, 0);
        roiManager("add");
        roiManager("select", roiManager("count")-1);
        roiManager("rename", "x=" + x_points[i] + ", y=" + y_points[i]);
    }
    roiManager("show all without labels");
}


    function gaussian_fit(data) {
        // Estimate initial parameters
        max_index = find_max_value(data);
        A = data[max_index]; // Amplitude
        mu = max_index; // Mean
        sigma = 1; // Standard deviation (initial guess)

        // Prepare x values
        x = newArray(data.length);
        for (i = 0; i < data.length; i++) {
            x[i] = i;
        }

        // Levenberg-Marquardt fit
        Fit.doFit("Gaussian", x, data);
        
        // Get the fitted parameters
        mu = Fit.p(2); // Mean (center) of the Gaussian

        return mu;
    }


function find_y_transition(column) {
	 
    gradient = newArray(column.length - 1);
    for (i = 0; i < column.length - 1; i++) {
        gradient[i] = column[i + 1] - column[i];
    }
    max_grad = 1e9;  // Initialize to a large positive number
    max_index = -1;
    min_threshold = 5; // Adjust this value to change sensitivity
    for (i = 0; i < gradient.length; i++) {
        if (gradient[i] < max_grad && abs(gradient[i]) > min_threshold) {
            max_grad = gradient[i];
            max_index = i;
        }
    }

    if (max_index >= 0) {
        // Interpolate for sub-pixel accuracy
        if (max_index > 0 && max_index < gradient.length - 1) {
            y1 = abs(gradient[max_index - 1]);
            y2 = abs(gradient[max_index]);
            y3 = abs(gradient[max_index + 1]);
            offset = 0.5 * (y1 - y3) / (y1 - 2*y2 + y3);
            return max_index + offset;
        }
    }

    return max_index;
}


function find_x_transition(row) {
	 
    gradient = newArray(row.length - 1);
    for (i = 0; i < row.length - 1; i++) {
        gradient[i] = row[i + 1] - row[i];
    }
    max_grad = -1;
    max_index = -1;
    min_threshold = 5; // Adjust this value to change sensitivity
    for (i = 0; i < gradient.length; i++) {
        if (abs(gradient[i]) > abs(max_grad) && abs(gradient[i]) > min_threshold && gradient[i] < 0) {
            max_grad = gradient[i];
            max_index = i;
        }
    }

    if (max_index >= 0) {
        // Interpolate for sub-pixel accuracy
        if (max_index > 0 && max_index < gradient.length - 1) {
            y1 = abs(gradient[max_index - 1]);
            y2 = abs(gradient[max_index]);
            y3 = abs(gradient[max_index + 1]);
            offset = 0.5 * (y1 - y3) / (y1 - 2*y2 + y3);
            return max_index + offset;
        }
    }

    return max_index;
}

    return max_index;
}

    function removeROIs(startX, startY, endX, endY) {
        nRois = roiManager("count");
        for (i = nRois - 1; i >= 0; i--) {
            roiManager("select", i);
            getSelectionBounds(rx, ry, rw, rh);
            if (rx >= startX && rx <= endX && ry >= startY && ry <= endY) {
                roiManager("delete");
            }
        }
    }

function saveROIsToCSV(imageName, iteration) {
    nRois = roiManager("count");
    if (nRois == 0) return;
    Dialog.create("Shrinking type");
    Dialog.addRadioButtonGroup("Is this even with NS or without NS", newArray("Without NS" , "With NS"), 1, 2, "Without NS");
    Dialog.addCheckbox("Close kymo", close_kymo);
    Dialog.show();
    eventType = Dialog.getRadioButton();
    close_kymo = Dialog.getCheckbox();
    filename = imageName + "_" + iteration + ".csv";
    if(eventType == "With NS")
        filename = "With_NS_" + imageName + "_" + iteration + ".csv";
    
    dir = getDirectory("image");
    if (dir == ""){
        dir = getDirectory("Choose directory for saving coordinates");
    }
        
    Path = dir + File.separator + "shrinking_line" + File.separator;
    filePath = Path + filename;
    
    if (!File.exists(Path)){
        File.makeDirectory(Path);
    }
    
    filelist = getFileList(Path);
    getDimensions(width, height, channels, slices, frames);

    while (arrayContains(filelist, filename)) {
        iteration++;
        filename = imageName + "_" + iteration + ".csv";
        filePath = Path + filename;
    }
	//xyCoor = newArray();
	
	pxValue = newArray(channels);
    csvContent = "X,Y";
    		for(ch_number = 1; ch_number <= channels; ch_number++){
				csvContent = csvContent + ",PxVl channel=" + ch_number ;
			}
	csvContent = csvContent + "\n" ;
    for (i = 0; i < nRois; i++) {
        roiManager("select", i);
        roiName = Roi.getName();
        xyCoor = split(roiName , ",");
        x = parseFloat(substring(xyCoor[0], 2));
        y = parseFloat(substring(xyCoor[1], 3));
		for(ch_number = 1; ch_number <= channels; ch_number++){
			Stack.setChannel(ch_number);
			pxValue[ch_number] = getPixel(round(x), round(y));
		}
        
        csvContent = csvContent + (x*pixelWidth) + "," + (y*interval) ;
        	for(ch_number = 1; ch_number <= channels; ch_number++){
			csvContent = csvContent + "," + pxValue[ch_number] ;
			}
			csvContent = csvContent + "\n";
    }

    File.saveString(csvContent, filePath);
    if(close_kymo){

            roiManager("deselect");
            roiManager("delete");
//            Overlay.remove;
//            setTool("polyline");
            imgID = getImageID();
            selectImage(imgID);
            img_name = getTitle();
            close(img_name) ;
            //print(imgID + " is closed");
			imgID = getImageID();
            selectImage(imgID);
            
            //exit();
    }
}
    // Function to check if an array contains a specific value
    function arrayContains(arr, value) {
        for (i = 0; i < arr.length; i++) {
            if (arr[i] == value) return true;
        }
        return false;
    }
}
function find_max_value(array) {
    max_value = 0;
    max_index = -1;
    for (i = 0; i < array.length; i++) {
        if (array[i] > max_value) {
            max_value = array[i];
            max_index = i;
        }
    }
    return max_index;
}
