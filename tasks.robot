*** Settings ***
Documentation       Template robot main suite.

Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    Screenshot
Library    RPA.Archive
Library    OperatingSystem

*** Variables ***
${receipt_dir}       ${OUTPUT_DIR}${/}receipts

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}    Download the Excel file, read it as a table, and return the result
    Set Global Variable    ${orders}
    Fill the form using orders.csv data    ${orders}
    Create a ZIP file of receipt PDF files
    Cleanup

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Wait Until Element Is Visible    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Click Button    OK

Download the Excel file, read it as a table, and return the result
    Download    https://robotsparebinindustries.com/orders.csv        overwrite=True
    Sleep    4s
    ${orders}=    Read table from CSV    orders.csv
    [Return]    ${orders}
Fill the form using orders.csv data
    [Arguments]    ${orders}
    FOR    ${row}    IN    @{orders}
        Fill and submit the form for one person    ${row}
        
    END

Fill and submit the form for one person
    [Arguments]    ${row}
    Select From List By Value    css:#head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder='Enter the part number for the legs']   ${row}[Legs]
    Input Text    address    ${row}[Address]
    ${screenshot}    Preview the robot    ${row}[Order number]
    Submit order    ${row}[Order number]    ${screenshot}

Preview the robot
    [Arguments]    ${ordernumber}
    Click Button    Preview
    Wait Until Element Is Visible    css:#robot-preview-image
    Set Local Variable    ${screenshot}    ${OUTPUT_DIR}${/}screenshot_${order_number}.png
    Screenshot    css:#robot-preview-image    ${screenshot}
    Sleep    1s
    [Return]    ${screenshot}

Submit order
    [Arguments]    ${ordernumber}    ${screenshot}
    Click Button    css:#order    
    ${errorPopUp}=    Does Page Contain Element    css:div.alert-danger
    WHILE    ${errorPopUp} == ${True}
        Log    entered
        Click Button    css:#order
        ${errorPopUp}=    Does Page Contain Element    css:div.alert-danger
    END
    Sleep    1s
    Export order receipt to PDF    ${ordernumber}    ${screenshot}
    Order another robot

Export order receipt to PDF
    [Arguments]    ${ordernumber}    ${screenshot}
    Wait Until Element Is Visible    css:#receipt
    ${reciept_html}=    Get Element Attribute    id:receipt   outerHTML
    Set Local Variable    ${file_path}    ${receipt_dir}${/}receipt_${order_number}.pdf
    Html To Pdf    ${reciept_html}    ${file_path}
    Sleep    1s
    Embed screenshot to the pdf    ${screenshot}    ${file_path}

Embed screenshot to the pdf
    [Arguments]    ${screenshot}    ${pdf}
    ${image_files} =    Create List    ${screenshot}:align=center
    Open Pdf    ${pdf}
    Add Files To Pdf    ${image_files}    ${pdf}    append=True
    Close Pdf  

Order another robot
    Click Button    css:#order-another
    Click Button    OK

Create a ZIP file of receipt PDF files
    ${zip_file_name} =    Set Variable    ${OUTPUT_DIR}${/}all_receipts.zip
    Archive Folder With Zip    ${receipt_dir}    ${zip_file_name}

Cleanup
    Close Browser
    Remove Directory    ${receipt_dir}       recursive=True