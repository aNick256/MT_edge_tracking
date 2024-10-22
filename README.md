# MT_edge_tracking
Microtubule edge tracking macro

### Edge Detector

The edge detector can be used to detect edges in images, primarily using the steepness of pixel intensity gradients within the selection rectangle as a marker. It is ideal for tracking microtubule edges in kymographs.

#### Usage Manual:

1. Open your image.
2. Drag and drop the `Edge_detector.ijm` file onto ImageJ and click "Run."
3. The wheel click will open the settings menu, which contains the following items:

   * **Rectangle Width and Height**: Sets the width and height of the scanning area within which you want to detect edges.
   * **Smoothing**: Applies the smooth function (`ImageJ/Process/Smooth`) the number of times specified by the entered value.
   * **Gradient Segment Length**: Specifies the length of the segment within which the steepness of the gradient is determined.
   * **Transition Detection Method**: Choose one of the following methods:
     * **Gradient**: Creates a point ROI (Region of Interest) at the site with the steepest intensity change within the gradient segment length in a given pixel row/column.
     * **Maximum**: Detects the pixel with the maximum intensity within the scanned pixel row/column. This could be useful in specific cases.
     * **Gaussian Fit**: Fits a Gaussian to the pixel row/column and creates a point ROI at the center of the Gaussian. This method may be useful for tracking diffusive particles in kymographs.

   * **Scan Direction**: Determines whether the scanning area is scanned row by row (X) or column by column (Y).
   * **Y Scan Direction**: The gradient function defaults to detecting transitions from higher to lower pixel intensities. If you want to detect edges that transition from high to low intensity (top to bottom), select `↑`. If the transition is from low to high intensity, select `↓`.
   * **Flip Image Horizontally**: Flips the image horizontally.
   * **Make Polyline**: Creates a polyline that connects the point ROIs. The number of points used to create the polyline can be at most the number of point ROIs, but the user can set a lower number to prevent sudden bends and jaggedness. Additionally, the "Fit Spline" option can make the polyline smoother.

4. After selecting your method, you can detect edges by positioning the scanning rectangle over your area of interest and clicking on the edges while holding the Shift key. To remove undesired points, wheel click on them while holding the Shift key. To remove all ROIs, left-click on the image and hold it for a second while moving the cursor.

5. Finally, hold the Control key and left-click to see the saving options. In this case, you will see the options used to categorize data in my experiments ('With NS' and 'Without NS'), but you can change these categories as needed. You can also check the `Close Kymo` option if you want the kymograph you analyzed to be closed after saving the coordinates of the edges.

6. By clicking OK in the prompt window, the macro will create a subdirectory in the image's directory called 'Shrinking_line'. The coordinates of the edges, along with the pixel intensities at those sites for each channel of the kymograph, will be saved in a `.csv` file.


