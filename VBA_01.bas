Attribute VB_Name = "Module1"

Sub CheckSpecificStaff()
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim i As Long
    Dim staffName As String
    Dim searchName As String
    Dim expiryDate As Date
    Dim lastCertDate As Date
    Dim creditsEarned As Double
    Dim creditsRequired As Double
    Dim staffFound As Boolean
   
    creditsRequired = 120 ' Required credits
    staffFound = False

    Set ws = ActiveSheet
    lastRow = ws.Cells(ws.Rows.Count, 3).End(xlUp).Row ' Find last row in Column C (Staff Name)

    ' Ask the user to enter a staff name
    searchName = InputBox("ㄎEnter the staff name to check:", "Staff Lookup")
   
    ' If the user clicks cancel or enters nothing, exit the macro
    If searchName = "" Then Exit Sub
   
    ' Loop through staff records
    For i = 2 To lastRow
        staffName = ws.Cells(i, 3).Value ' Column C (Staff Name)

        If StrComp(staffName, searchName, vbTextCompare) = 0 Then ' Case-insensitive match
            staffFound = True ' Mark staff as found
           
            ' Handle Last Certification Date (Check if it's a valid date)
            If IsDate(ws.Cells(i, 5).Value) Then
                lastCertDate = ws.Cells(i, 5).Value ' Column E (Last Certification Date)
            Else
                lastCertDate = 0 ' Default to 0 if not a valid date
            End If

            ' Handle Expiry Date (Check if it's a valid date)
            If IsDate(ws.Cells(i, 6).Value) Then
                expiryDate = ws.Cells(i, 6).Value ' Column F (Certificate Expiry Date)
            Else
                expiryDate = 0 ' Default to 0 if not a valid date
            End If

            ' Handle Credits Earned (Ensure it's a number)
            If IsNumeric(ws.Cells(i, 11).Value) Then
                creditsEarned = ws.Cells(i, 11).Value ' Column K (Credits Earned)
            Else
                creditsEarned = 0 ' Default to 0 if not a number
            End If

            ' Construct message box result
            Dim resultMessage As String
            resultMessage = "Staff: " & staffName & vbCrLf & _
                            "Last Certification Date: " & lastCertDate & vbCrLf & _
                            "Certificate Expiry Date: " & expiryDate & vbCrLf & _
                            "Credits Earned: " & creditsEarned & "/" & creditsRequired
           
            ' Check if expiry is within 180 days
            If expiryDate <> 0 And expiryDate < Date + 180 Then
                ws.Cells(i, 6).Font.Color = RGB(255, 153, 153) ' Light Red Font
                resultMessage = resultMessage & vbCrLf & "Expiry is within 180 days!"
               
                ' Check if staff needs more credits
                If creditsEarned < creditsRequired Then
                    resultMessage = resultMessage & vbCrLf & "Needs " & (creditsRequired - creditsEarned) & " more credits!"
                End If
            End If
           
            ' Show message box with staff details
            MsgBox resultMessage, vbInformation, "Certification Status"
           
            Exit For
        End If
    Next i

    ' If staff was not found, notify the user
    If Not staffFound Then
        MsgBox "Staff '" & searchName & "' not found in the records.", vbExclamation, "Search Result"
    End If
End Sub

