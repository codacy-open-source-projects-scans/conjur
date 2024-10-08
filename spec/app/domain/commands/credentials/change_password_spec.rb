require 'spec_helper'

describe Commands::Credentials::ChangePassword do
  let(:role) { double(Role, id: 'role') }
  let(:password) { 'the_password' }
  let(:client_ip) { 'my-client-ip' }

  let(:err_message) { 'the error message' }

  let(:audit_log) { double(::Audit.logger)}

  let(:audit_success) do
    ::Audit::Event::Password.new(
      user_id: role.id,
      client_ip: client_ip,
      success: true
    )
  end

  let(:audit_failure) do
    ::Audit::Event::Password.new(
      user_id: role.id,
      client_ip: client_ip,
      success: false,
      error_message: err_message
    )
  end

  subject do
    Commands::Credentials::ChangePassword.new(
      audit_log: audit_log
    )
  end

  it 'updates the password for the given User' do
    # Expect it to update the password on the role
    expect(role).to receive(:password=).with(password)

    # Expect it to log a successful audit message
    expect(audit_log).to receive(:log).with(audit_success)

    # Call the command
    subject.call(role: role,  password: password, client_ip: client_ip)
  end

  it 'bubbles up exceptions' do
    # Assume the database update fails. This could be caused by an
    # invalid password, database issues, etc.
    allow(role).to receive(:password=).and_raise(err_message)

    # Expect it to log a failed audit message
    expect(audit_log).to receive(:log).with(audit_failure)

    # Expect the command to raise the original exception
    expect do
      subject.call(role: role,  password: password, client_ip: client_ip)
    end.to raise_error(err_message)
  end
end
